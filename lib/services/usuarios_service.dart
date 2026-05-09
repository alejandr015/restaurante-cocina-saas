import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo del usuario tal como lo devuelve la Edge Function
class UsuarioRestaurante {
  final String userId;
  final String email;
  final String rol;
  final String? nombre;
  final DateTime creadoEn;

  UsuarioRestaurante({
    required this.userId,
    required this.email,
    required this.rol,
    required this.nombre,
    required this.creadoEn,
  });

  factory UsuarioRestaurante.fromJson(Map<String, dynamic> json) =>
      UsuarioRestaurante(
        userId: json['user_id'] as String,
        email: json['email'] as String,
        rol: json['rol'] as String,
        nombre: json['nombre'] as String?,
        creadoEn: DateTime.parse(json['creado_en'] as String),
      );
}

/// Servicio que llama la Edge Function `gestionar-usuarios`
/// para listar, crear, eliminar usuarios y cambiar contraseñas.
class UsuariosService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<UsuarioRestaurante> _usuarios = [];
  bool _cargando = false;
  String? _error;

  List<UsuarioRestaurante> get usuarios => _usuarios;
  bool get cargando => _cargando;
  String? get error => _error;

  /// Trae la lista de usuarios del restaurante actual
  Future<void> cargar() async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      final response = await _supabase.functions.invoke(
        'gestionar-usuarios',
        body: {'accion': 'listar'},
      );

      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('error')) {
        _error = data['error'] as String;
        _cargando = false;
        notifyListeners();
        return;
      }

      final lista = data['usuarios'] as List<dynamic>;
      _usuarios = lista
          .map((u) => UsuarioRestaurante.fromJson(u as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.email.compareTo(b.email));

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar usuarios: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  /// Crea un nuevo usuario en el restaurante actual
  /// Devuelve null si OK, o mensaje de error
  Future<String?> crear({
    required String email,
    required String password,
    required String rol,
    String? nombre,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'gestionar-usuarios',
        body: {
          'accion': 'crear',
          'email': email,
          'password': password,
          'rol': rol,
          'nombre': nombre ?? '',
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('error')) {
        return data['error'] as String;
      }

      // Recargar lista después de crear
      await cargar();
      return null;
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Elimina un usuario del restaurante (también lo borra de Auth)
  Future<String?> eliminar(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'gestionar-usuarios',
        body: {
          'accion': 'eliminar',
          'user_id': userId,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('error')) {
        return data['error'] as String;
      }

      // Quitarlo de la lista local
      _usuarios.removeWhere((u) => u.userId == userId);
      notifyListeners();
      return null;
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Cambia la contraseña de un usuario
  Future<String?> cambiarPassword({
    required String userId,
    required String nuevaPassword,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'gestionar-usuarios',
        body: {
          'accion': 'actualizar_password',
          'user_id': userId,
          'password': nuevaPassword,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('error')) {
        return data['error'] as String;
      }

      return null;
    } catch (e) {
      return 'Error: $e';
    }
  }

  void limpiar() {
    _usuarios = [];
    _error = null;
    _cargando = false;
    notifyListeners();
  }
}
