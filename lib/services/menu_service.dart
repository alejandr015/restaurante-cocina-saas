import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_models.dart';

/// Servicio que carga el menú (categorías + productos) y las mesas
/// del restaurante actual y se mantiene SINCRONIZADO en tiempo real
/// con cualquier cambio que haga el admin desde su panel.
///
/// Está protegido contra duplicados: si llega un evento INSERT por
/// Realtime de un registro que ya está en la lista local, lo ignora.
class MenuService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Categoria> _categorias = [];
  List<Producto> _productos = [];
  List<Mesa> _mesas = [];

  bool _cargando = true;
  String? _error;

  RealtimeChannel? _channelCategorias;
  RealtimeChannel? _channelProductos;
  RealtimeChannel? _channelMesas;

  // ---- Getters ----
  List<Categoria> get categorias =>
      _categorias.where((c) => c.activa).toList();

  List<Producto> get productos =>
      _productos.where((p) => p.disponible).toList();

  List<Mesa> get mesas => _mesas.where((m) => m.activa).toList();

  bool get cargando => _cargando;
  String? get error => _error;

  List<Producto> productosDeCategoria(String categoriaId) {
    return _productos
        .where((p) => p.categoriaId == categoriaId && p.disponible)
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
  }

  // ---- Carga inicial ----

  Future<void> cargar() async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      final results = await Future.wait([
        _supabase
            .from('categorias_menu')
            .select()
            .order('orden', ascending: true),
        _supabase
            .from('productos_menu')
            .select()
            .order('orden', ascending: true),
        _supabase.from('mesas').select().order('numero', ascending: true),
      ]);

      _categorias = (results[0] as List)
          .map((j) => Categoria.fromJson(j as Map<String, dynamic>))
          .toList();

      _productos = (results[1] as List)
          .map((j) => Producto.fromJson(j as Map<String, dynamic>))
          .toList();

      _mesas = (results[2] as List)
          .map((j) => Mesa.fromJson(j as Map<String, dynamic>))
          .toList();

      _cargando = false;
      notifyListeners();

      _suscribirseRealtime();
    } catch (e) {
      _error = 'Error al cargar el menú: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  // ---- Realtime ----

  void _suscribirseRealtime() {
    if (_channelCategorias != null) return;

    _channelCategorias = _supabase
        .channel('menu_categorias_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'categorias_menu',
          callback: _manejarCambioCategoria,
        )
        .subscribe();

    _channelProductos = _supabase
        .channel('menu_productos_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'productos_menu',
          callback: _manejarCambioProducto,
        )
        .subscribe();

    _channelMesas = _supabase
        .channel('menu_mesas_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'mesas',
          callback: _manejarCambioMesa,
        )
        .subscribe();
  }

  void _manejarCambioCategoria(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final nueva = Categoria.fromJson(payload.newRecord);
        // Anti-duplicado: si ya está, no la agreguemos otra vez
        if (_categorias.any((c) => c.id == nueva.id)) return;
        _categorias.add(nueva);
        _categorias.sort((a, b) => a.orden.compareTo(b.orden));
        break;
      case PostgresChangeEvent.update:
        final actualizada = Categoria.fromJson(payload.newRecord);
        final idx = _categorias.indexWhere((c) => c.id == actualizada.id);
        if (idx != -1) {
          _categorias[idx] = actualizada;
        } else {
          _categorias.add(actualizada);
          _categorias.sort((a, b) => a.orden.compareTo(b.orden));
        }
        break;
      case PostgresChangeEvent.delete:
        _categorias.removeWhere((c) => c.id == payload.oldRecord['id']);
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void _manejarCambioProducto(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final nuevo = Producto.fromJson(payload.newRecord);
        // Anti-duplicado: si ya está, no lo agreguemos otra vez
        if (_productos.any((p) => p.id == nuevo.id)) return;
        _productos.add(nuevo);
        _productos.sort((a, b) => a.orden.compareTo(b.orden));
        break;
      case PostgresChangeEvent.update:
        final actualizado = Producto.fromJson(payload.newRecord);
        final idx = _productos.indexWhere((p) => p.id == actualizado.id);
        if (idx != -1) {
          _productos[idx] = actualizado;
        } else {
          _productos.add(actualizado);
          _productos.sort((a, b) => a.orden.compareTo(b.orden));
        }
        break;
      case PostgresChangeEvent.delete:
        _productos.removeWhere((p) => p.id == payload.oldRecord['id']);
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void _manejarCambioMesa(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final nueva = Mesa.fromJson(payload.newRecord);
        if (_mesas.any((m) => m.id == nueva.id)) return;
        _mesas.add(nueva);
        break;
      case PostgresChangeEvent.update:
        final actualizada = Mesa.fromJson(payload.newRecord);
        final idx = _mesas.indexWhere((m) => m.id == actualizada.id);
        if (idx != -1) {
          _mesas[idx] = actualizada;
        } else {
          _mesas.add(actualizada);
        }
        break;
      case PostgresChangeEvent.delete:
        _mesas.removeWhere((m) => m.id == payload.oldRecord['id']);
        break;
      default:
        break;
    }
    notifyListeners();
  }

  // ---- Limpieza ----

  void limpiar() {
    _channelCategorias?.unsubscribe();
    _channelCategorias = null;
    _channelProductos?.unsubscribe();
    _channelProductos = null;
    _channelMesas?.unsubscribe();
    _channelMesas = null;

    _categorias = [];
    _productos = [];
    _mesas = [];
    _cargando = true;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _channelCategorias?.unsubscribe();
    _channelProductos?.unsubscribe();
    _channelMesas?.unsubscribe();
    super.dispose();
  }
}
