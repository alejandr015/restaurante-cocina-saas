import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio con todas las acciones administrativas:
/// gestión de restaurante, categorías, productos, mesas, etc.
class AdminService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _guardando = false;
  String? _ultimoError;

  bool get guardando => _guardando;
  String? get ultimoError => _ultimoError;

  // =========================================================
  // RESTAURANTE
  // =========================================================

  Future<String?> actualizarRestaurante({
    required String id,
    String? nombre,
    String? colorPrimario,
    String? whatsappNumero,
  }) async {
    return _ejecutar(() async {
      final updates = <String, dynamic>{};
      if (nombre != null) updates['nombre'] = nombre;
      if (colorPrimario != null) updates['color_primario'] = colorPrimario;
      if (whatsappNumero != null) updates['whatsapp_numero'] = whatsappNumero;
      if (updates.isEmpty) return;
      await _supabase.from('restaurantes').update(updates).eq('id', id);
    });
  }

  // =========================================================
  // CATEGORÍAS
  // =========================================================

  Future<String?> crearCategoria({
    required String restauranteId,
    required String nombre,
    int orden = 0,
  }) async {
    return _ejecutar(() async {
      await _supabase.from('categorias_menu').insert({
        'restaurante_id': restauranteId,
        'nombre': nombre,
        'orden': orden,
        'activa': true,
      });
    });
  }

  Future<String?> actualizarCategoria({
    required String id,
    String? nombre,
    bool? activa,
    int? orden,
  }) async {
    return _ejecutar(() async {
      final updates = <String, dynamic>{};
      if (nombre != null) updates['nombre'] = nombre;
      if (activa != null) updates['activa'] = activa;
      if (orden != null) updates['orden'] = orden;
      if (updates.isEmpty) return;
      await _supabase.from('categorias_menu').update(updates).eq('id', id);
    });
  }

  Future<String?> eliminarCategoria(String id) async {
    return _ejecutar(() async {
      final productos = await _supabase
          .from('productos_menu')
          .select('id')
          .eq('categoria_id', id);
      if ((productos as List).isNotEmpty) {
        throw Exception(
            'Esta categoría tiene productos. Desactívala o mueve los productos a otra categoría primero.');
      }
      await _supabase.from('categorias_menu').delete().eq('id', id);
    });
  }

  // =========================================================
  // PRODUCTOS
  // =========================================================

  Future<String?> crearProducto({
    required String restauranteId,
    required String categoriaId,
    required String nombre,
    String? descripcion,
    required double precio,
    int orden = 0,
  }) async {
    return _ejecutar(() async {
      await _supabase.from('productos_menu').insert({
        'restaurante_id': restauranteId,
        'categoria_id': categoriaId,
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'orden': orden,
        'disponible': true,
      });
    });
  }

  Future<String?> actualizarProducto({
    required String id,
    String? nombre,
    String? descripcion,
    double? precio,
    String? categoriaId,
    bool? disponible,
    int? orden,
  }) async {
    return _ejecutar(() async {
      final updates = <String, dynamic>{};
      if (nombre != null) updates['nombre'] = nombre;
      if (descripcion != null) updates['descripcion'] = descripcion;
      if (precio != null) updates['precio'] = precio;
      if (categoriaId != null) updates['categoria_id'] = categoriaId;
      if (disponible != null) updates['disponible'] = disponible;
      if (orden != null) updates['orden'] = orden;
      if (updates.isEmpty) return;
      await _supabase.from('productos_menu').update(updates).eq('id', id);
    });
  }

  Future<String?> eliminarProducto(String id) async {
    return _ejecutar(() async {
      await _supabase.from('productos_menu').delete().eq('id', id);
    });
  }

  // =========================================================
  // MESAS
  // =========================================================

  Future<String?> crearMesa({
    required String restauranteId,
    required String numero,
    required int capacidad,
  }) async {
    return _ejecutar(() async {
      // Validar que el número no exista ya
      final existentes = await _supabase
          .from('mesas')
          .select('id')
          .eq('restaurante_id', restauranteId)
          .eq('numero', numero);
      if ((existentes as List).isNotEmpty) {
        throw Exception('Ya existe una mesa con el número "$numero"');
      }

      await _supabase.from('mesas').insert({
        'restaurante_id': restauranteId,
        'numero': numero,
        'capacidad': capacidad,
        'activa': true,
      });
    });
  }

  Future<String?> actualizarMesa({
    required String id,
    String? numero,
    int? capacidad,
    bool? activa,
  }) async {
    return _ejecutar(() async {
      final updates = <String, dynamic>{};
      if (numero != null) updates['numero'] = numero;
      if (capacidad != null) updates['capacidad'] = capacidad;
      if (activa != null) updates['activa'] = activa;
      if (updates.isEmpty) return;
      await _supabase.from('mesas').update(updates).eq('id', id);
    });
  }

  Future<String?> eliminarMesa(String id) async {
    return _ejecutar(() async {
      await _supabase.from('mesas').delete().eq('id', id);
    });
  }

  // =========================================================
  // HELPER
  // =========================================================

  Future<String?> _ejecutar(Future<void> Function() accion) async {
    try {
      _guardando = true;
      _ultimoError = null;
      notifyListeners();

      await accion();

      _guardando = false;
      notifyListeners();
      return null;
    } catch (e) {
      _ultimoError = e.toString();
      _guardando = false;
      notifyListeners();
      return _extraerMensaje(e);
    }
  }

  String _extraerMensaje(Object e) {
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) return msg.substring(11);
    return msg;
  }
}
