import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/pedidos_service.dart';
import 'services/menu_service.dart';
import 'services/carrito_service.dart';
import 'services/mesas_service.dart';
import 'services/admin_service.dart';
import 'services/historial_service.dart';
import 'services/usuarios_service.dart';
import 'screens/login_screen.dart';
import 'screens/cocina_screen.dart';
import 'screens/mesero_screen.dart';
import 'screens/admin_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthService()..verificarSesion(),
        ),
        ChangeNotifierProvider(create: (_) => PedidosService()),
        ChangeNotifierProvider(create: (_) => MenuService()),
        ChangeNotifierProvider(create: (_) => CarritoService()),
        ChangeNotifierProvider(create: (_) => MesasService()),
        ChangeNotifierProvider(create: (_) => AdminService()),
        ChangeNotifierProvider(create: (_) => HistorialService()),
        ChangeNotifierProvider(create: (_) => UsuariosService()),
      ],
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          final colorPrimario = auth.restaurante != null
              ? AppTheme.hexToColor(
                  auth.restaurante!['color_primario'] as String,
                )
              : AppTheme.rojo;

          return MaterialApp(
            title: 'Restaurante',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.tema(colorPrimario: colorPrimario),
            home: const Gateway(),
          );
        },
      ),
    );
  }
}

class Gateway extends StatelessWidget {
  const Gateway({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (!auth.autenticado || auth.restaurante == null) {
          return const LoginScreen();
        }

        switch (auth.rol) {
          case RolUsuario.admin:
            return const AdminScreen();
          case RolUsuario.cocina:
            return const CocinaScreen();
          case RolUsuario.mesero:
            return const MeseroScreen();
          case RolUsuario.desconocido:
            return _buildSinRol(context, auth);
        }
      },
    );
  }

  Widget _buildSinRol(BuildContext context, AuthService auth) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: AppTheme.amarillo,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sin rol asignado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu cuenta no tiene un rol asignado en ningún restaurante.\nContacta al administrador.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textoSecundario),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => auth.logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
