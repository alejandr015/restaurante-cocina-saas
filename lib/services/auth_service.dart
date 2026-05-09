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
class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, dynamic>? _restaurante;
  RolUsuario _rol = RolUsuario.desconocido;

  Map<String, dynamic>? get restaurante => _restaurante;
  RolUsuario get rol => _rol;

  bool get autenticado => _supabase.auth.currentUser != null;

  Future<String?> login(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
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
    notifyListeners();
  }

  /// Carga restaurante y rol en una sola consulta combinada
  Future<void> _cargarDatosUsuario() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Trae el vínculo del usuario con su restaurante (incluye el rol)
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

    // Ahora trae los datos del restaurante (RLS ya lo filtra solo al suyo)
    final restauranteResponse = await _supabase
        .from('restaurantes')
        .select()
        .eq('id', vinculoResponse['restaurante_id'])
        .maybeSingle();

    _restaurante = restauranteResponse;
  }

  Future<void> verificarSesion() async {
    if (autenticado) {
      await _cargarDatosUsuario();
      notifyListeners();
    }
  }
}
