import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/super_admin_service.dart';

/// Panel del Super Admin (dueño del SaaS).
/// Muestra todos los restaurantes y permite crear nuevos.
class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminService>().cargarRestaurantes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      body: SafeArea(
        child: Consumer<SuperAdminService>(
          builder: (context, service, _) {
            return Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildContenido(service)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirCrearRestaurante(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo restaurante'),
        backgroundColor: AppTheme.rojo,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('👑', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Super Admin Panel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textoPrimario,
                  ),
                ),
                Text(
                  'Gestión de restaurantes del SaaS',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Cerrar sesión',
            color: AppTheme.textoSecundario,
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido(SuperAdminService service) {
    if (service.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (service.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.rojo),
              const SizedBox(height: 12),
              Text(service.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => service.cargarRestaurantes(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => service.cargarRestaurantes(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResumen(service),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Restaurantes activos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textoPrimario,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (service.restaurantes.isEmpty)
              _buildEmpty()
            else
              ...service.restaurantes.map(_buildRestauranteCard),
          ],
        ),
      ),
    );
  }

  Widget _buildResumen(SuperAdminService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: Row(
        children: [
          _buildStat(
            icono: Icons.store_mall_directory_outlined,
            valor: '${service.restaurantes.length}',
            label: 'Restaurantes',
            color: AppTheme.rojo,
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icono,
    required String valor,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textoPrimario,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textoSecundario,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestauranteCard(RestauranteResumen r) {
    final color = AppTheme.hexToColor(r.colorPrimario);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.restaurant_menu,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textoPrimario,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '/${r.slug}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textoTerciario,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.borde, width: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textoTerciario),
            SizedBox(height: 8),
            Text(
              'Aún no hay restaurantes',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textoSecundario,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Click en "Nuevo restaurante" para empezar',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textoTerciario,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirCrearRestaurante(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CrearRestauranteDialog(),
    );
  }
}

// ============================================
// Diálogo: Crear Restaurante
// ============================================

class _CrearRestauranteDialog extends StatefulWidget {
  const _CrearRestauranteDialog();

  @override
  State<_CrearRestauranteDialog> createState() =>
      _CrearRestauranteDialogState();
}

class _CrearRestauranteDialogState extends State<_CrearRestauranteDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _adminNombreCtrl = TextEditingController();
  final _adminTelefonoCtrl = TextEditingController();
  final _numMesasCtrl = TextEditingController(text: '10');
  final _prefijoMesaCtrl = TextEditingController(text: 'M');

  Color _colorSeleccionado = const Color(0xFFE63946);
  bool _enviando = false;
  String? _error;

  static const _coloresSugeridos = [
    Color(0xFFE63946), // Rojo
    Color(0xFFD63031), // Rojo oscuro
    Color(0xFF1976D2), // Azul
    Color(0xFF388E3C), // Verde
    Color(0xFFEF9F27), // Naranja
    Color(0xFF8E44AD), // Morado
    Color(0xFF2C3E50), // Gris azulado
    Color(0xFFE91E63), // Rosa
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _adminNombreCtrl.dispose();
    _adminTelefonoCtrl.dispose();
    _numMesasCtrl.dispose();
    _prefijoMesaCtrl.dispose();
    super.dispose();
  }

  String _hexFromColor(Color c) {
    return '#${c.r.toInt().toRadixString(16).padLeft(2, '0')}'
            '${c.g.toInt().toRadixString(16).padLeft(2, '0')}'
            '${c.b.toInt().toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  String _generarPassword() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    var seed = now;
    final result = StringBuffer();
    for (int i = 0; i < 12; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      result.write(chars[seed % chars.length]);
    }
    return result.toString();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _enviando = true;
      _error = null;
    });

    final service = context.read<SuperAdminService>();
    final resultado = await service.crearRestaurante(
      nombre: _nombreCtrl.text.trim(),
      colorPrimario: _hexFromColor(_colorSeleccionado),
      numMesas: int.parse(_numMesasCtrl.text.trim()),
      prefijoMesa: _prefijoMesaCtrl.text.trim().toUpperCase(),
      adminEmail: _emailCtrl.text.trim().toLowerCase(),
      adminPassword: _passwordCtrl.text.trim(),
      adminNombre: _adminNombreCtrl.text.trim(),
      adminTelefono: _adminTelefonoCtrl.text.trim().isEmpty
          ? null
          : _adminTelefonoCtrl.text.trim(),
    );

    if (!mounted) return;

    if (resultado.exito) {
      Navigator.of(context).pop();
      _mostrarCredenciales(resultado);
    } else {
      setState(() {
        _enviando = false;
        _error = resultado.error;
      });
    }
  }

  void _mostrarCredenciales(ResultadoCrearRestaurante r) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CredencialesDialog(resultado: r),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Nuevo restaurante',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _enviando
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSeccion('🏪 Datos del restaurante'),
                        const SizedBox(height: 8),
                        _buildCampo(
                          ctrl: _nombreCtrl,
                          label: 'Nombre del restaurante',
                          hint: 'Ej: Pizzería Don Pepe',
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Requerido'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Color de marca',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _coloresSugeridos.map((c) {
                            final seleccionado = c.toARGB32() ==
                                _colorSeleccionado.toARGB32();
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _colorSeleccionado = c),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: seleccionado
                                        ? AppTheme.textoPrimario
                                        : AppTheme.borde,
                                    width: seleccionado ? 2 : 0.5,
                                  ),
                                ),
                                child: seleccionado
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCampo(
                                ctrl: _numMesasCtrl,
                                label: 'Número de mesas',
                                keyboard: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) {
                                  final n = int.tryParse(v ?? '');
                                  if (n == null || n < 0 || n > 100) {
                                    return '0-100';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 100,
                              child: _buildCampo(
                                ctrl: _prefijoMesaCtrl,
                                label: 'Prefijo',
                                hint: 'M, T, ...',
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Req'
                                        : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSeccion('👤 Cuenta del administrador'),
                        const SizedBox(height: 8),
                        _buildCampo(
                          ctrl: _adminNombreCtrl,
                          label: 'Nombre completo del admin',
                          hint: 'Ej: Juan Pérez',
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Requerido'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        _buildCampo(
                          ctrl: _emailCtrl,
                          label: 'Email del admin',
                          hint: 'admin@donpepe.com',
                          keyboard: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCampo(
                                ctrl: _passwordCtrl,
                                label: 'Password (mín 6)',
                                hint: 'Auto o personalizado',
                                validator: (v) {
                                  if (v == null || v.length < 6) {
                                    return 'Mín 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Generar password segura',
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: () {
                                setState(() {
                                  _passwordCtrl.text = _generarPassword();
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCampo(
                          ctrl: _adminTelefonoCtrl,
                          label: 'Teléfono (opcional)',
                          hint: '+57...',
                          keyboard: TextInputType.phone,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.rojoFondo,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppTheme.rojoOscuro,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.rojoOscuro,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _enviando
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _enviando ? null : _crear,
                      icon: _enviando
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.rocket_launch, size: 18),
                      label: Text(_enviando ? 'Creando...' : 'Crear restaurante'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.rojo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeccion(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textoPrimario,
      ),
    );
  }

  Widget _buildCampo({
    required TextEditingController ctrl,
    required String label,
    String? hint,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      validator: validator,
      enabled: !_enviando,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}

// ============================================
// Diálogo: Mostrar credenciales del restaurante creado
// ============================================

class _CredencialesDialog extends StatelessWidget {
  final ResultadoCrearRestaurante resultado;

  const _CredencialesDialog({required this.resultado});

  void _copiar(BuildContext context, String texto, String label) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado al portapapeles'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copiarTodo(BuildContext context) {
    final texto = '''
Restaurante: ${resultado.restaurante!.nombre}

Acceso al panel de administración:
Email: ${resultado.adminEmail}
Password: ${resultado.adminPassword}

¡Bienvenido!''';
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Credenciales completas copiadas'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = resultado.restaurante!;
    final color = AppTheme.hexToColor(r.colorPrimario);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.verdeFondo,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.verdeOscuro,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡Restaurante creado exitosamente!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.verdeOscuro,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.nombre,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '/${r.slug}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textoTerciario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '📋 Credenciales para enviar al cliente:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textoSecundario,
                ),
              ),
              const SizedBox(height: 8),
              _buildCredencial(
                context,
                label: 'Email',
                valor: resultado.adminEmail!,
              ),
              const SizedBox(height: 6),
              _buildCredencial(
                context,
                label: 'Password',
                valor: resultado.adminPassword!,
                esPassword: true,
              ),
              const SizedBox(height: 6),
              _buildCredencial(
                context,
                label: 'Nombre',
                valor: resultado.adminNombre!,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.amarilloFondo,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.amarilloOscuro,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Guarda esta password ahora. NO podrás verla de nuevo.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.amarilloOscuro,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copiarTodo(context),
                      icon: const Icon(Icons.copy_all, size: 16),
                      label: const Text('Copiar todo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Listo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredencial(
    BuildContext context, {
    required String label,
    required String valor,
    bool esPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.fondo,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textoSecundario,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              valor,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textoPrimario,
                fontFamily: esPassword ? 'monospace' : null,
                fontWeight: esPassword ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'Copiar $label',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => _copiar(context, valor, label),
          ),
        ],
      ),
    );
  }
}
