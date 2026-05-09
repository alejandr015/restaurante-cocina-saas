import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_models.dart';

/// Servicio que mantiene el carrito de pedido del mesero en memoria.
/// Al confirmar, inserta una fila en la tabla `pedidos` de Supabase
/// y limpia el carrito.
class CarritoService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Mesa? _mesa;
  final List<ItemCarrito> _items = [];
  String? _notasGenerales;
  String? _nombreCliente;

  // ---- Getters ----
  Mesa? get mesa => _mesa;
  List<ItemCarrito> get items => List.unmodifiable(_items);
  String? get notasGenerales => _notasGenerales;
  String? get nombreCliente => _nombreCliente;

  bool get vacio => _items.isEmpty;
  int get cantidadTotal =>
      _items.fold(0, (sum, item) => sum + item.cantidad);
  double get total =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);

  // ---- Acciones de mesa ----

  void seleccionarMesa(Mesa mesa) {
    _mesa = mesa;
    notifyListeners();
  }

  void deseleccionarMesa() {
    _mesa = null;
    notifyListeners();
  }

  // ---- Acciones de items ----

  /// Agrega un producto al carrito. Si ya estaba, suma 1 a la cantidad.
  void agregarProducto(Producto producto) {
    final idx = _items.indexWhere((i) => i.producto.id == producto.id);
    if (idx >= 0) {
      _items[idx].cantidad += 1;
    } else {
      _items.add(ItemCarrito(producto: producto, cantidad: 1));
    }
    notifyListeners();
  }

  /// Resta 1 a la cantidad. Si llega a 0, lo quita del carrito.
  void quitarProducto(Producto producto) {
    final idx = _items.indexWhere((i) => i.producto.id == producto.id);
    if (idx < 0) return;

    if (_items[idx].cantidad > 1) {
      _items[idx].cantidad -= 1;
    } else {
      _items.removeAt(idx);
    }
    notifyListeners();
  }

  /// Establece una cantidad específica
  void establecerCantidad(Producto producto, int cantidad) {
    final idx = _items.indexWhere((i) => i.producto.id == producto.id);
    if (idx < 0) return;

    if (cantidad <= 0) {
      _items.removeAt(idx);
    } else {
      _items[idx].cantidad = cantidad;
    }
    notifyListeners();
  }

  /// Quita el producto del carrito completamente
  void eliminarProducto(Producto producto) {
    _items.removeWhere((i) => i.producto.id == producto.id);
    notifyListeners();
  }

  /// Cuántas unidades de un producto hay en el carrito
  int cantidadDe(Producto producto) {
    final item = _items
        .where((i) => i.producto.id == producto.id)
        .firstOrNull;
    return item?.cantidad ?? 0;
  }

  // ---- Notas y cliente ----

  void setNotasGenerales(String? notas) {
    _notasGenerales = notas?.trim().isEmpty == true ? null : notas?.trim();
    notifyListeners();
  }

  void setNombreCliente(String? nombre) {
    _nombreCliente = nombre?.trim().isEmpty == true ? null : nombre?.trim();
    notifyListeners();
  }

  // ---- Confirmar pedido ----

  /// Inserta el pedido en Supabase y limpia el carrito.
  /// Devuelve null si todo OK, o el mensaje de error si falla.
  Future<String?> confirmarPedido({
    required String restauranteId,
  }) async {
    if (_mesa == null) return 'Selecciona una mesa primero';
    if (_items.isEmpty) return 'El carrito está vacío';

    try {
      // Generar número de pedido legible (timestamp último 5 dígitos)
      final numero = DateTime.now().millisecondsSinceEpoch
          .toString()
          .substring(8);

      await _supabase.from('pedidos').insert({
        'numero_pedido': numero,
        'tipo': 'local',
        'estado': 'nuevo',
        'cliente_nombre': _nombreCliente ?? 'Mesa ${_mesa!.numero}',
        'mesa': _mesa!.numero,
        'items': _items.map((i) => i.toPedidoJson()).toList(),
        'notas': _notasGenerales,
        'total': total,
        'restaurante_id': restauranteId,
      });

      // Limpiar después de confirmar
      _limpiarCarrito();
      notifyListeners();
      return null;
    } catch (e) {
      return 'Error al confirmar pedido: $e';
    }
  }

  void _limpiarCarrito() {
    _items.clear();
    _notasGenerales = null;
    _nombreCliente = null;
    _mesa = null;
  }

  /// Limpia todo (al cerrar sesión por ejemplo)
  void limpiar() {
    _limpiarCarrito();
    notifyListeners();
  }
}
