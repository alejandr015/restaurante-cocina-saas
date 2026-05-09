import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de un restaurante en la lista
class RestauranteResumen {
  final String id;
  final String nombre;
  final String slug;
  final String colorPrimario;
  final int? totalUsuarios;
  final int? totalProductos;

  RestauranteResumen({
    required this.id,
    required this.nombre,
    required this.slug,
    required this.colorPrimario,
    this.totalUsuarios,
    this.totalProductos,
  });

  factory RestauranteResumen.fromJson(Map<String, dynamic> json) =>
      RestauranteResumen(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        slug: json['slug'] as String,
        colorPrimario: json['color_primario'] as String? ?? '#3B82F6',
      );
}

/// Resultado de crear un restaurante
class ResultadoCrearRestaurante {
  final bool exito;
  final String? error;
  final RestauranteResumen? restaurante;
  final String? adminEmail;
  final String? adminPassword;
  final String? adminNombre;

  ResultadoCrearRestaurante.exito({
    required this.restaurante,
    required this.adminEmail,
    required this.adminPassword,
    required this.adminNombre,
  })  : exito = true,
        error = null;

  ResultadoCrearRestaurante.error(this.error)
      : exito = false,
        restaurante = null,
        adminEmail = null,
        adminPassword = null,
        adminNombre = null;
}

/// Servicio para operaciones de Super Admin (dueño del SaaS)
class SuperAdminService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _esSuperAdmin = false;
  bool _verificado = false;
  List<RestauranteResumen> _restaurantes = [];
  bool _cargando = false;
  String? _error;

  bool get esSuperAdmin => _esSuperAdmin;
  bool get verificado => _verificado;
  List<RestauranteResumen> get restaurantes => _restaurantes;
  bool get cargando => _cargando;
  String? get error => _error;

  /// Verifica si el usuario actual es super_admin
  Future<void> verificarSuperAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _esSuperAdmin = false;
      _verificado = true;
      notifyListeners();
      return;
    }

    try {
      final response = await _supabase
          .from('super_admins')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      _esSuperAdmin = response != null;
      _verificado = true;
      notifyListeners();
    } catch (e) {
      _esSuperAdmin = false;
      _verificado = true;
      notifyListeners();
    }
  }

  /// Carga todos los restaurantes (solo funciona si es super admin gracias a RLS)
  Future<void> cargarRestaurantes() async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('restaurantes')
          .select('id, nombre, slug, color_primario')
          .order('nombre');

      _restaurantes = (response as List)
          .map((r) => RestauranteResumen.fromJson(r as Map<String, dynamic>))
          .toList();

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar restaurantes: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  /// Crea un nuevo restaurante completo (con admin) llamando a la Edge Function
  Future<ResultadoCrearRestaurante> crearRestaurante({
    required String nombre,
    required String colorPrimario,
    required int numMesas,
    required String prefijoMesa,
    required String adminEmail,
    required String adminPassword,
    required String adminNombre,
    String? adminTelefono,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'crear-restaurante',
        body: {
          'nombre': nombre,
          'color_primario': colorPrimario,
          'num_mesas': numMesas,
          'prefijo_mesa': prefijoMesa,
          'admin_email': adminEmail,
          'admin_password': adminPassword,
          'admin_nombre': adminNombre,
          if (adminTelefono != null && adminTelefono.isNotEmpty)
            'admin_telefono': adminTelefono,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('error')) {
        return ResultadoCrearRestaurante.error(data['error'] as String);
      }

      // Recargar lista
      await cargarRestaurantes();

      final rest = data['restaurante'] as Map<String, dynamic>;
      final admin = data['admin'] as Map<String, dynamic>;

      return ResultadoCrearRestaurante.exito(
        restaurante: RestauranteResumen.fromJson(rest),
        adminEmail: admin['email'] as String,
        adminPassword: admin['password'] as String,
        adminNombre: admin['nombre'] as String,
      );
    } catch (e) {
      return ResultadoCrearRestaurante.error('Error: $e');
    }
  }

  void limpiar() {
    _esSuperAdmin = false;
    _verificado = false;
    _restaurantes = [];
    _error = null;
    _cargando = false;
    notifyListeners();
  }
}
