import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';

/// Sección "Información del restaurante" del panel admin.
/// Permite editar nombre, color y número de WhatsApp.
class AdminInfoScreen extends StatefulWidget {
  const AdminInfoScreen({super.key});

  @override
  State<AdminInfoScreen> createState() => _AdminInfoScreenState();
}

class _AdminInfoScreenState extends State<AdminInfoScreen> {
  final _nombreCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  String _color = '#E24B4A';
  bool _modificado = false;

  // Lista de colores predefinidos para elegir
  final List<String> _coloresPredefinidos = [
    '#E24B4A', // Rojo
    '#EF9F27', // Naranja
    '#F0CB35', // Amarillo
    '#639922', // Verde
    '#2EAD7E', // Verde mar
    '#378ADD', // Azul
    '#5B5DD4', // Índigo
    '#8B45BC', // Púrpura
    '#D6429B', // Rosa
    '#1A1A19', // Negro
    '#73726C', // Gris
    '#985E37', // Marrón
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    final r = context.read<AuthService>().restaurante;
    if (r == null) return;
    _nombreCtrl.text = r['nombre'] as String? ?? '';
    _whatsappCtrl.text = r['whatsapp_numero'] as String? ?? '';
    _color = r['color_primario'] as String? ?? '#E24B4A';
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final auth = context.read<AuthService>();
    final admin = context.read<AdminService>();
    final r = auth.restaurante;
    if (r == null) return;

    final error = await admin.actualizarRestaurante(
      id: r['id'] as String,
      nombre: _nombreCtrl.text.trim(),
      colorPrimario: _color,
      whatsappNumero: _whatsappCtrl.text.trim(),
    );

    if (!mounted) return;

    if (error == null) {
      // Recargar info del usuario para que la app refleje los cambios
      await auth.verificarSesion();
      if (!mounted) return;
      setState(() => _modificado = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Cambios guardados'),
          backgroundColor: AppTheme.verde,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.rojo),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminService>();
    final colorActual = AppTheme.hexToColor(_color);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del restaurante',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppTheme.textoPrimario,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Personaliza cómo se muestra tu restaurante',
            style: TextStyle(fontSize: 13, color: AppTheme.textoSecundario),
          ),
          const SizedBox(height: 24),

          // Card: Datos básicos
          _buildCard(
            titulo: 'Datos básicos',
            children: [
              _buildLabel('Nombre del restaurante'),
              TextField(
                controller: _nombreCtrl,
                onChanged: (_) => setState(() => _modificado = true),
                decoration: const InputDecoration(
                  hintText: 'Ej: Rapi Broasted',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('Número de WhatsApp'),
              TextField(
                controller: _whatsappCtrl,
                onChanged: (_) => setState(() => _modificado = true),
                decoration: const InputDecoration(
                  hintText: 'Ej: +573001234567',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.phone, size: 18),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 4),
              const Text(
                'Este es el número desde el cual los clientes pueden hacer pedidos',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textoTerciario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card: Color
          _buildCard(
            titulo: 'Color de marca',
            children: [
              _buildLabel('Color primario'),
              const SizedBox(height: 8),
              // Vista previa
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.fondo,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borde, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorActual,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _color.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textoPrimario,
                            ),
                          ),
                          const Text(
                            'Color actual',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Paleta
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _coloresPredefinidos
                    .map((c) => _buildSwatch(c))
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Botón Guardar
          if (_modificado)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: admin.guardando ? null : _guardar,
                icon: admin.guardando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(
                  admin.guardando ? 'Guardando...' : 'Guardar cambios',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorActual,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwatch(String colorHex) {
    final c = AppTheme.hexToColor(colorHex);
    final seleccionado = _color == colorHex;
    return GestureDetector(
      onTap: () => setState(() {
        _color = colorHex;
        _modificado = true;
      }),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: seleccionado ? AppTheme.textoPrimario : Colors.transparent,
            width: 3,
          ),
        ),
        child: seleccionado
            ? const Icon(Icons.check, color: Colors.white, size: 22)
            : null,
      ),
    );
  }

  Widget _buildCard({
    required String titulo,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textoPrimario,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textoSecundario,
        ),
      ),
    );
  }
}
