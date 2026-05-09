import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/usuarios_service.dart';

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsuariosService>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final usuariosService = context.watch<UsuariosService>();
    final colorRestaurante =
        AppTheme.hexToColor(auth.restaurante!['color_primario'] as String);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(usuariosService, colorRestaurante),
          const SizedBox(height: 12),
          Expanded(
            child: _buildContenido(usuariosService, colorRestaurante),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UsuariosService service, Color colorRestaurante) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Usuarios',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textoPrimario,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${service.usuarios.length} usuario${service.usuarios.length != 1 ? "s" : ""} configurado${service.usuarios.length != 1 ? "s" : ""}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textoSecundario,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () => service.cargar(),
          tooltip: 'Actualizar',
          color: AppTheme.textoSecundario,
        ),
        const SizedBox(width: 4),
        ElevatedButton.icon(
          onPressed: () => _dialogoCrearUsuario(),
          icon: const Icon(Icons.person_add, size: 18),
          label: const Text('Nuevo usuario'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorRestaurante,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildContenido(UsuariosService service, Color colorRestaurante) {
    if (service.cargando && service.usuarios.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (service.error != null && service.usuarios.isEmpty) {
      return _buildError(service);
    }

    if (service.usuarios.isEmpty) {
      return _buildVacio(colorRestaurante);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: service.usuarios.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppTheme.borde),
        itemBuilder: (context, i) =>
            _buildFilaUsuario(service.usuarios[i], colorRestaurante),
      ),
    );
  }

  Widget _buildFilaUsuario(UsuarioRestaurante u, Color colorRestaurante) {
    final esYo = Supabase.instance.client.auth.currentUser?.id == u.userId;
    final formatoFecha = DateFormat('dd MMM yyyy', 'es');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          _buildAvatar(u, colorRestaurante),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      u.nombre?.isNotEmpty == true ? u.nombre! : u.email,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textoPrimario,
                      ),
                    ),
                    if (esYo) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.fondo,
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: AppTheme.borde, width: 0.5),
                        ),
                        child: const Text(
                          'Yo',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textoSecundario,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    _buildBadgeRol(u.rol, colorRestaurante),
                  ],
                ),
                const SizedBox(height: 2),
                if (u.nombre?.isNotEmpty == true)
                  Text(
                    u.email,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                Text(
                  'Creado el ${formatoFecha.format(u.creadoEn)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textoTerciario,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 18),
            color: AppTheme.textoSecundario,
            visualDensity: VisualDensity.compact,
            onPressed: () => _menuUsuario(u, esYo),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UsuarioRestaurante u, Color colorRestaurante) {
    final iniciales = _obtenerIniciales(u.nombre, u.email);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _colorParaRol(u.rol, colorRestaurante).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          iniciales,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _colorParaRol(u.rol, colorRestaurante),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeRol(String rol, Color colorRestaurante) {
    final color = _colorParaRol(rol, colorRestaurante);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _labelRol(rol),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildError(UsuariosService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.rojo),
            const SizedBox(height: 12),
            Text(
              service.error ?? 'Error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textoSecundario),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => service.cargar(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacio(Color colorRestaurante) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppTheme.textoTerciario.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No hay usuarios',
            style: TextStyle(color: AppTheme.textoSecundario),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _dialogoCrearUsuario(),
            icon: const Icon(Icons.person_add),
            label: const Text('Crear primer usuario'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorRestaurante,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Acciones ----

  void _menuUsuario(UsuarioRestaurante u, bool esYo) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Cambiar contraseña'),
              onTap: () {
                Navigator.of(context).pop();
                _dialogoCambiarPassword(u);
              },
            ),
            if (!esYo)
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.rojo),
                title: const Text(
                  'Eliminar usuario',
                  style: TextStyle(color: AppTheme.rojo),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmarEliminar(u);
                },
              )
            else
              const ListTile(
                leading: Icon(Icons.info_outline,
                    color: AppTheme.textoTerciario),
                title: Text(
                  'No puedes eliminar tu propia cuenta',
                  style: TextStyle(color: AppTheme.textoTerciario),
                ),
                enabled: false,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _dialogoCrearUsuario() async {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String rol = 'mesero';
    bool ocultarPassword = true;

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Nuevo usuario'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'cocina@restaurante.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email, size: 18),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: ocultarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    hintText: 'Mínimo 6 caracteres',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        ocultarPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 18,
                      ),
                      onPressed: () => setStateDialog(
                        () => ocultarPassword = !ocultarPassword,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Rol',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['mesero', 'cocina', 'admin'].map((r) {
                    final activo = rol == r;
                    return GestureDetector(
                      onTap: () => setStateDialog(() => rol = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: activo
                              ? AppTheme.rojo
                              : AppTheme.fondo,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: activo ? AppTheme.rojo : AppTheme.borde,
                          ),
                        ),
                        child: Text(
                          _labelRol(r),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: activo
                                ? Colors.white
                                : AppTheme.textoPrimario,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (guardar != true || !mounted) return;

    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text;
    final nombre = nombreCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showError('Email inválido');
      return;
    }
    if (password.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    _showLoading('Creando usuario...');

    final error = await context.read<UsuariosService>().crear(
          email: email,
          password: password,
          rol: rol,
          nombre: nombre.isEmpty ? null : nombre,
        );

    if (!mounted) return;
    Navigator.of(context).pop();

    if (error != null) {
      _showError(error);
    } else {
      _showOk('Usuario creado correctamente');
    }
  }

  Future<void> _dialogoCambiarPassword(UsuarioRestaurante u) async {
    final passwordCtrl = TextEditingController();
    bool ocultarPassword = true;

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          icon: const Icon(Icons.lock_reset, size: 40),
          title: Text('Nueva contraseña para\n${u.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14)),
          content: SizedBox(
            width: 360,
            child: TextField(
              controller: passwordCtrl,
              autofocus: true,
              obscureText: ocultarPassword,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                hintText: 'Mínimo 6 caracteres',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    ocultarPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    size: 18,
                  ),
                  onPressed: () => setStateDialog(
                    () => ocultarPassword = !ocultarPassword,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );

    if (guardar != true || !mounted) return;
    final password = passwordCtrl.text;
    if (password.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    _showLoading('Actualizando contraseña...');
    final error = await context.read<UsuariosService>().cambiarPassword(
          userId: u.userId,
          nuevaPassword: password,
        );
    if (!mounted) return;
    Navigator.of(context).pop();

    if (error != null) {
      _showError(error);
    } else {
      _showOk('Contraseña actualizada');
    }
  }

  Future<void> _confirmarEliminar(UsuarioRestaurante u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline,
            color: AppTheme.rojo, size: 48),
        title: Text('¿Eliminar a ${u.email}?'),
        content: const Text(
          'Esta acción no se puede deshacer.\n'
          'El usuario perderá acceso inmediatamente.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rojo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    _showLoading('Eliminando usuario...');
    final error = await context.read<UsuariosService>().eliminar(u.userId);
    if (!mounted) return;
    Navigator.of(context).pop();

    if (error != null) {
      _showError(error);
    } else {
      _showOk('Usuario eliminado');
    }
  }

  // ---- Helpers ----

  String _obtenerIniciales(String? nombre, String email) {
    if (nombre != null && nombre.trim().isNotEmpty) {
      final partes = nombre.trim().split(' ');
      if (partes.length >= 2) {
        return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
      }
      return partes[0].substring(0, partes[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return email.substring(0, email.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _colorParaRol(String rol, Color colorRestaurante) {
    switch (rol) {
      case 'admin':
        return colorRestaurante;
      case 'cocina':
        return AppTheme.amarilloOscuro;
      case 'mesero':
        return AppTheme.verde;
      default:
        return AppTheme.textoSecundario;
    }
  }

  String _labelRol(String rol) {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'cocina':
        return 'Cocina';
      case 'mesero':
        return 'Mesero';
      default:
        return rol;
    }
  }

  void _showOk(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✓ $msg'), backgroundColor: AppTheme.verde),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.rojo),
    );
  }

  void _showLoading(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text(msg),
          ],
        ),
      ),
    );
  }
}
