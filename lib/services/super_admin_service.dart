import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de un restaurante en la lista
class RestauranteResumen {
  final String id;
  final String nombre;
  final String slug;
  final String colorPrimario;
  final bool activo;

  RestauranteResumen({
    required this.id,
    required this.nombre,
    required this.slug,
    required this.colorPrimario,
    required this.activo,
  });

  factory RestauranteResumen.fromJson(Map<String, dynamic> json) =>
      RestauranteResumen(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        slug: json['slug'] as String,
        colorPrimario: json['color_primario'] as String? ?? '#3B82F6',
        activo: json['activo'] as bool? ?? true,
      );

  RestauranteResumen copyWith({bool? activo}) => RestauranteResumen(
        id: id,
        nombre: nombre,
        slug: slug,
        colorPrimario: colorPrimario,
        activo: activo ?? this.activo,
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

/// Servicio para operaciones de Super Admin (dueño del SaaS).
class SuperAdminService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _crearRestauranteFunction = 'swift-handler';

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

  SuperAdminService() {
    verificarSuperAdmin();

    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        verificarSuperAdmin();
      } else if (event == AuthChangeEvent.signedOut) {
        _esSuperAdmin = false;
        _verificado = true;
        _restaurantes = [];
        notifyListeners();
      }
    });
  }

  Future<void> verificarSuperAdmin() async {
    final user = _supabase.auth.currentUser;
    debugPrint('🔍 [SuperAdmin] Verificando user: ${user?.email}');

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

      debugPrint(
        '✅ [SuperAdmin] ${_esSuperAdmin ? "ES" : "NO es"} super admin',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [SuperAdmin] Error verificando: $e');
      _esSuperAdmin = false;
      _verificado = true;
      notifyListeners();
    }
  }

  Future<void> cargarRestaurantes() async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('restaurantes')
          .select('id, nombre, slug, color_primario, activo')
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

  /// Activa o desactiva un restaurante.
  /// Cuando está desactivado, los usuarios del restaurante NO pueden iniciar sesión.
  /// Devuelve null si OK, o mensaje de error.
  Future<String?> toggleActivo({
    required String restauranteId,
    required bool nuevoEstado,
  }) async {
    try {
      debugPrint(
        '🔄 [SuperAdmin] ${nuevoEstado ? "Activando" : "Desactivando"} restaurante $restauranteId',
      );

      // Optimistic update local
      final idx =
          _restaurantes.indexWhere((r) => r.id == restauranteId);
      if (idx >= 0) {
        _restaurantes[idx] = _restaurantes[idx].copyWith(activo: nuevoEstado);
        notifyListeners();
      }

      // Update en BD
      await _supabase
          .from('restaurantes')
          .update({'activo': nuevoEstado})
          .eq('id', restauranteId);

      debugPrint('✅ [SuperAdmin] Estado actualizado correctamente');
      return null;
    } catch (e) {
      debugPrint('❌ [SuperAdmin] Error toggle: $e');
      // Rollback local
      final idx =
          _restaurantes.indexWhere((r) => r.id == restauranteId);
      if (idx >= 0) {
        _restaurantes[idx] =
            _restaurantes[idx].copyWith(activo: !nuevoEstado);
        notifyListeners();
      }
      return 'Error al cambiar estado: $e';
    }
  }

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
      debugPrint('🚀 [SuperAdmin] Llamando función...');

      final response = await _supabase.functions.invoke(
        _crearRestauranteFunction,
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

      debugPrint('📥 [SuperAdmin] Status: ${response.status}');

      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('error')) {
        return ResultadoCrearRestaurante.error(data['error'] as String);
      }

      await cargarRestaurantes();

      final rest = data['restaurante'] as Map<String, dynamic>;
      final admin = data['admin'] as Map<String, dynamic>;

      // Asegurar que el campo activo viene (default true para nuevos)
      rest['activo'] = rest['activo'] ?? true;

      return ResultadoCrearRestaurante.exito(
        restaurante: RestauranteResumen.fromJson(rest),
        adminEmail: admin['email'] as String,
        adminPassword: admin['password'] as String,
        adminNombre: admin['nombre'] as String,
      );
    } catch (e) {
      debugPrint('❌ [SuperAdmin] Error crear: $e');
      return ResultadoCrearRestaurante.error('Error: $e');
    }
  }

  void limpiar() {
    _esSuperAdmin = false;
    _restaurantes = [];
    _error = null;
    _cargando = false;
    notifyListeners();
  }
}
