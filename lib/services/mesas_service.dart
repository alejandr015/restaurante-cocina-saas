import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pedido.dart';

/// Estado calculado de una mesa: si está ocupada y los pedidos abiertos.
class EstadoMesa {
  final String numeroMesa;
  final List<Pedido> pedidosAbiertos;

  EstadoMesa({
    required this.numeroMesa,
    required this.pedidosAbiertos,
  });

  bool get ocupada => pedidosAbiertos.isNotEmpty;

  /// Total acumulado de todos los pedidos abiertos
  double get totalCuenta =>
      pedidosAbiertos.fold(0.0, (sum, p) => sum + (p.total ?? 0));

  /// Cantidad total de items en todos los pedidos
  int get cantidadItems => pedidosAbiertos.fold(
      0,
      (sum, p) => sum + p.items.fold<int>(0, (s, i) => s + i.cantidad));

  /// El pedido más antiguo (para calcular cuánto lleva ocupada)
  DateTime? get inicioOcupacion {
    if (pedidosAbiertos.isEmpty) return null;
    return pedidosAbiertos
        .map((p) => p.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  String get tiempoOcupada {
    final inicio = inicioOcupacion;
    if (inicio == null) return '';
    final mins = DateTime.now().difference(inicio).inMinutes;
    if (mins < 1) return 'recién';
    if (mins < 60) return '$mins min';
    final h = (mins / 60).floor();
    return '${h}h ${mins % 60}min';
  }
}

/// Servicio que mantiene en tiempo real el estado de las mesas
/// (cuáles están ocupadas, cuántos pedidos tienen, qué tiempo llevan).
class MesasService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Pedido> _pedidosAbiertos = [];
  bool _cargando = true;
  String? _error;

  RealtimeChannel? _channel;
  Timer? _refreshTimer;

  // Estados que cuentan como "mesa ocupada"
  static const _estadosAbiertos = ['nuevo', 'preparacion', 'listo', 'entregado'];

  bool get cargando => _cargando;
  String? get error => _error;

  /// Devuelve el estado de una mesa específica
  EstadoMesa estadoDe(String numeroMesa) {
    final pedidos = _pedidosAbiertos
        .where((p) => p.mesa == numeroMesa)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return EstadoMesa(numeroMesa: numeroMesa, pedidosAbiertos: pedidos);
  }

  Future<void> inicializar() async {
    await _cargar();
    _suscribirseRealtime();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      notifyListeners();
    });
  }

  Future<void> _cargar() async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('pedidos')
          .select()
          .eq('tipo', 'local')
          .inFilter('estado', _estadosAbiertos)
          .order('created_at', ascending: true);

      _pedidosAbiertos = (response as List)
          .map((j) => Pedido.fromJson(j as Map<String, dynamic>))
          .toList();

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar mesas: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  void _suscribirseRealtime() {
    _channel = _supabase
        .channel('mesas_pedidos_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pedidos',
          callback: _manejarCambio,
        )
        .subscribe();
  }

  void _manejarCambio(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final nuevo = Pedido.fromJson(payload.newRecord);
        if (nuevo.tipo == TipoPedido.local &&
            _estadosAbiertos.contains(nuevo.estado.name)) {
          _pedidosAbiertos.add(nuevo);
        }
        break;

      case PostgresChangeEvent.update:
        final actualizado = Pedido.fromJson(payload.newRecord);
        final idx = _pedidosAbiertos.indexWhere((p) => p.id == actualizado.id);

        if (actualizado.tipo == TipoPedido.local &&
            _estadosAbiertos.contains(actualizado.estado.name)) {
          if (idx != -1) {
            _pedidosAbiertos[idx] = actualizado;
          } else {
            _pedidosAbiertos.add(actualizado);
          }
        } else {
          // Cambió a estado cerrado/cancelado → quitarlo
          if (idx != -1) {
            _pedidosAbiertos.removeAt(idx);
          }
        }
        break;

      case PostgresChangeEvent.delete:
        _pedidosAbiertos.removeWhere((p) => p.id == payload.oldRecord['id']);
        break;

      default:
        break;
    }
    notifyListeners();
  }

  /// Cierra la cuenta de una mesa: marca todos sus pedidos abiertos como 'cerrado'
  Future<String?> cerrarCuentaMesa(String numeroMesa) async {
    try {
      final estado = estadoDe(numeroMesa);
      if (estado.pedidosAbiertos.isEmpty) {
        return 'Esta mesa no tiene pedidos abiertos';
      }

      final ids = estado.pedidosAbiertos.map((p) => p.id).toList();
      await _supabase
          .from('pedidos')
          .update({'estado': 'cerrado'})
          .inFilter('id', ids);

      return null;
    } catch (e) {
      return 'Error al cerrar cuenta: $e';
    }
  }

  void limpiar() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _channel?.unsubscribe();
    _channel = null;
    _pedidosAbiertos = [];
    _cargando = true;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }
}
