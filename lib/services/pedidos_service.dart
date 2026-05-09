import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pedido.dart';

/// Servicio que gestiona los pedidos en tiempo real.
/// Carga la lista inicial desde Supabase y mantiene una suscripción
/// activa para recibir cambios al instante (insert, update, delete).
class PedidosService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Pedido> _pedidos = [];
  bool _conectado = false;
  bool _cargando = true;
  String? _error;

  RealtimeChannel? _channel;
  Timer? _refreshTimer;

  // ---- Getters públicos ----
  List<Pedido> get pedidos => _pedidos;
  bool get conectado => _conectado;
  bool get cargando => _cargando;
  String? get error => _error;

  /// Pedidos filtrados por estado (para columnas del kanban)
  List<Pedido> get pedidosNuevos =>
      _pedidos.where((p) => p.estado == EstadoPedido.nuevo).toList();

  List<Pedido> get pedidosEnPreparacion =>
      _pedidos.where((p) => p.estado == EstadoPedido.preparacion).toList();

  List<Pedido> get pedidosListos =>
      _pedidos.where((p) => p.estado == EstadoPedido.listo).toList();

  // ---- Inicialización ----

  /// Llama esto al iniciar sesión: carga pedidos y se suscribe a cambios
  Future<void> inicializar() async {
    await _cargarPedidos();
    _suscribirseRealtime();

    // Cada 30 segundos refresca la UI para que el "tiempo transcurrido"
    // de cada pedido se mantenga actualizado
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      notifyListeners();
    });
  }

  Future<void> _cargarPedidos() async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('pedidos')
          .select()
          .inFilter('estado', ['nuevo', 'preparacion', 'listo'])
          .order('created_at', ascending: true);

      _pedidos = (response as List)
          .map((json) => Pedido.fromJson(json as Map<String, dynamic>))
          .toList();

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar pedidos: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  void _suscribirseRealtime() {
    _channel = _supabase
        .channel('pedidos_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pedidos',
          callback: _manejarCambioRealtime,
        )
        .subscribe((status, [error]) {
      _conectado = status == RealtimeSubscribeStatus.subscribed;
      notifyListeners();
    });
  }

  void _manejarCambioRealtime(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final nuevo = Pedido.fromJson(payload.newRecord);
        // Solo agregamos si está en un estado que mostramos
        if ([EstadoPedido.nuevo, EstadoPedido.preparacion, EstadoPedido.listo]
            .contains(nuevo.estado)) {
          _pedidos.add(nuevo);
          _onPedidoNuevo?.call(nuevo);
        }
        break;

      case PostgresChangeEvent.update:
        final actualizado = Pedido.fromJson(payload.newRecord);
        final idx = _pedidos.indexWhere((p) => p.id == actualizado.id);

        if (idx != -1) {
          // Si pasó a entregado/cancelado, sale del tablero
          if ([EstadoPedido.entregado, EstadoPedido.cancelado]
              .contains(actualizado.estado)) {
            _pedidos.removeAt(idx);
          } else {
            _pedidos[idx] = actualizado;
          }
        } else {
          // No estaba en la lista pero ahora aplica → agregarlo
          if ([EstadoPedido.nuevo, EstadoPedido.preparacion, EstadoPedido.listo]
              .contains(actualizado.estado)) {
            _pedidos.add(actualizado);
          }
        }
        break;

      case PostgresChangeEvent.delete:
        _pedidos.removeWhere((p) => p.id == payload.oldRecord['id']);
        break;

      default:
        break;
    }
    notifyListeners();
  }

  // ---- Callback opcional para sonido de notificación ----
  void Function(Pedido)? _onPedidoNuevo;

  void setOnPedidoNuevo(void Function(Pedido)? callback) {
    _onPedidoNuevo = callback;
  }

  // ---- Acciones sobre pedidos ----

  Future<void> aceptarPedido(int id) async =>
      _cambiarEstado(id, EstadoPedido.preparacion);

  Future<void> marcarListo(int id) async =>
      _cambiarEstado(id, EstadoPedido.listo);

  Future<void> marcarEntregado(int id) async =>
      _cambiarEstado(id, EstadoPedido.entregado);

  Future<void> cancelarPedido(int id) async =>
      _cambiarEstado(id, EstadoPedido.cancelado);

  Future<void> _cambiarEstado(int id, EstadoPedido nuevoEstado) async {
    try {
      await _supabase
          .from('pedidos')
          .update({'estado': nuevoEstado.name}).eq('id', id);
    } catch (e) {
      _error = 'Error al actualizar pedido: $e';
      notifyListeners();
    }
  }

  // ---- Limpieza ----

  Future<void> reconectar() async {
    await _channel?.unsubscribe();
    await _cargarPedidos();
    _suscribirseRealtime();
  }

  /// Llama esto al cerrar sesión: detiene realtime y limpia la lista
  Future<void> limpiar() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _channel?.unsubscribe();
    _channel = null;
    _pedidos = [];
    _conectado = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }
}
