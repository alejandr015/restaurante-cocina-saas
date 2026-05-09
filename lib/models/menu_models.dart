/// Modelos para la app del mesero.
///
/// Mesa       → mesa física del restaurante
/// Categoria  → grupo de productos (ej: "Bebidas")
/// Producto   → plato individual del menú
/// ItemCarrito → producto + cantidad + notas en el carrito antes de enviar

class Mesa {
  final String id;
  final String numero;
  final int capacidad;
  final bool activa;

  Mesa({
    required this.id,
    required this.numero,
    required this.capacidad,
    required this.activa,
  });

  factory Mesa.fromJson(Map<String, dynamic> json) => Mesa(
        id: json['id'] as String,
        numero: json['numero'] as String,
        capacidad: (json['capacidad'] as int?) ?? 4,
        activa: (json['activa'] as bool?) ?? true,
      );
}

class Categoria {
  final String id;
  final String nombre;
  final int orden;
  final bool activa;

  Categoria({
    required this.id,
    required this.nombre,
    required this.orden,
    required this.activa,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        orden: (json['orden'] as int?) ?? 0,
        activa: (json['activa'] as bool?) ?? true,
      );
}

class Producto {
  final String id;
  final String? categoriaId;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? imagenUrl;
  final bool disponible;
  final int orden;

  Producto({
    required this.id,
    required this.categoriaId,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.imagenUrl,
    required this.disponible,
    required this.orden,
  });

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
        id: json['id'] as String,
        categoriaId: json['categoria_id'] as String?,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        precio: (json['precio'] as num).toDouble(),
        imagenUrl: json['imagen_url'] as String?,
        disponible: (json['disponible'] as bool?) ?? true,
        orden: (json['orden'] as int?) ?? 0,
      );
}

/// Item del carrito: un producto con su cantidad y notas particulares.
/// Sigue siendo un objeto local (no se guarda en BD hasta confirmar pedido).
class ItemCarrito {
  final Producto producto;
  int cantidad;
  String? notas;

  ItemCarrito({
    required this.producto,
    this.cantidad = 1,
    this.notas,
  });

  double get subtotal => producto.precio * cantidad;

  /// Convierte a JSON para guardar en la columna `items` (jsonb) de pedidos
  Map<String, dynamic> toPedidoJson() => {
        'nombre': producto.nombre,
        'cantidad': cantidad,
        'precio': producto.precio,
      };
}
