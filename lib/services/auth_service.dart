import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Roles posibles dentro de un restaurante
enum RolUsuario {
  admin,
  cocina,
  mesero,
  desconocido;

  static RolUsuario fromString(String? value) {
    switch (value) {
      case 'admin':
        return RolUsuario.admin;
      case 'cocina':
        return RolUsuario.cocina;
      case 'mesero':
        return RolUsuario.mesero;
      default:
        return RolUsuario.desconocido;
    }
  }
}

/// Servicio de autenticación.
/// Maneja login/logout y carga la información del restaurante
/// y el rol del usuario logueado.
///
/// IMPORTANTE: si el restaurante está desactivado (activo=false), NO permite login
/// (excepto para super admins, que pueden entrar siempre).
class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, dynamic>? _restaurante;
  RolUsuario _rol = RolUsuario.desconocido;
  bool _restauranteDesactivado = false;

  Map<String, dynamic>? get restaurante => _restaurante;
  RolUsuario get rol => _rol;
  bool get autenticado => _supabase.auth.currentUser != null;
  
  /// True si el último intento de login falló porque el restaurante está desactivado
  bool get restauranteDesactivado => _restauranteDesactivado;

  Future<String?> login(String email, String password) async {
    try {
      _restauranteDesactivado = false;
      
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Verificar si es super admin (los super admins SIEMPRE pueden entrar)
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final esSuperAdmin = await _esSuperAdmin(user.id);
        
        if (!esSuperAdmin) {
          // Para usuarios normales: validar que el restaurante esté activo
          final restauranteActivo = await _validarRestauranteActivo(user.id);
          
          if (!restauranteActivo) {
            // Cerrar sesión y devolver error
            await _supabase.auth.signOut();
            _restauranteDesactivado = true;
            notifyListeners();
            return 'Esta cuenta está desactivada. Contacta a tu administrador del SaaS.';
          }
        }
      }

      await _cargarDatosUsuario();
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _restaurante = null;
    _rol = RolUsuario.desconocido;
    _restauranteDesactivado = false;
    notifyListeners();
  }

  /// Verifica si el user es super admin
  Future<bool> _esSuperAdmin(String userId) async {
    try {
      final response = await _supabase
          .from('super_admins')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Verifica que el restaurante del usuario esté activo
  Future<bool> _validarRestauranteActivo(String userId) async {
    try {
      // Obtener restaurante_id del usuario
      final vinculo = await _supabase
          .from('usuarios_restaurante')
          .select('restaurante_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (vinculo == null) {
        // Sin vínculo a restaurante → no puede entrar igual
        return false;
      }

      // Verificar el flag "activo" del restaurante
      final restaurante = await _supabase
          .from('restaurantes')
          .select('activo')
          .eq('id', vinculo['restaurante_id'])
          .maybeSingle();

      if (restaurante == null) return false;
      return restaurante['activo'] == true;
    } catch (e) {
      // En caso de error, ser permisivo para no bloquear por bugs
      return true;
    }
  }

  /// Carga restaurante y rol en una sola consulta combinada
  Future<void> _cargarDatosUsuario() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Trae el vínculo del usuario con su restaurante
    final vinculoResponse = await _supabase
        .from('usuarios_restaurante')
        .select('rol, restaurante_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (vinculoResponse == null) {
      _rol = RolUsuario.desconocido;
      _restaurante = null;
      return;
    }

    _rol = RolUsuario.fromString(vinculoResponse['rol'] as String?);

    final restauranteResponse = await _supabase
        .from('restaurantes')
        .select()
        .eq('id', vinculoResponse['restaurante_id'])
        .maybeSingle();

    _restaurante = restauranteResponse;
  }

  /// Re-verifica si el restaurante sigue activo. 
  /// Si fue desactivado mientras estaba en sesión → cierra sesión.
  /// Llamar periódicamente o cuando se sospeche cambio.
  Future<bool> verificarRestauranteSigueActivo() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    
    // Super admins no se ven afectados
    final esSuperAdmin = await _esSuperAdmin(user.id);
    if (esSuperAdmin) return true;
    
    final activo = await _validarRestauranteActivo(user.id);
    if (!activo) {
      // Forzar logout
      await logout();
      _restauranteDesactivado = true;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> verificarSesion() async {
    if (autenticado) {
      await _cargarDatosUsuario();
      notifyListeners();
    }
  }
}
