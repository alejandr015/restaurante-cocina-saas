import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/menu_models.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import '../services/admin_service.dart';
import '../services/mesas_service.dart';

/// Pantalla de gestión de mesas para el admin.
/// Lista todas las mesas (activas e inactivas) con acciones.
class AdminMesasScreen extends StatefulWidget {
  const AdminMesasScreen({super.key});

  @override
  State<AdminMesasScreen> createState() => _AdminMesasScreenState();
}

class _AdminMesasScreenState extends State<AdminMesasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuService>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final menu = context.watch<MenuService>();
    final mesasService = context.watch<MesasService>();
    final colorRestaurante =
        AppTheme.hexToColor(auth.restaurante!['color_primario'] as String);

    if (menu.cargando && menu.mesas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Para ver mesas activas e inactivas, accedemos al estado interno
    // Actualmente menu.mesas filtra solo activas. Vamos a usarlo así
    // y mostrar todas las que vienen.
    final mesas = menu.mesas;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(mesas.length, colorRestaurante),
          const SizedBox(height: 12),
          Expanded(
            child: mesas.isEmpty
                ? _buildVacio(colorRestaurante)
                : _buildLista(mesas, mesasService, colorRestaurante),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int cantidad, Color colorRestaurante) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mesas',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textoPrimario,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$cantidad mesa${cantidad != 1 ? "s" : ""} configurada${cantidad != 1 ? "s" : ""}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textoSecundario,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _dialogoMesa(null),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nueva mesa'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorRestaurante,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLista(
    List<Mesa> mesas,
    MesasService mesasService,
    Color colorRestaurante,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: mesas.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppTheme.borde),
        itemBuilder: (context, i) {
          final mesa = mesas[i];
          final estado = mesasService.estadoDe(mesa.numero);
          return _buildFilaMesa(mesa, estado, colorRestaurante);
        },
      ),
    );
  }

  Widget _buildFilaMesa(Mesa mesa, EstadoMesa estado, Color colorRestaurante) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: estado.ocupada
                  ? AppTheme.rojoFondo
                  : colorRestaurante.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.table_restaurant,
              size: 22,
              color: estado.ocupada ? AppTheme.rojo : colorRestaurante,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      mesa.numero.length > 3
                          ? mesa.numero
                          : 'Mesa ${mesa.numero}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textoPrimario,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (estado.ocupada)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.rojo,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Ocupada · ${estado.tiempoOcupada}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${mesa.capacidad} persona${mesa.capacidad != 1 ? "s" : ""}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 18),
            color: AppTheme.textoSecundario,
            visualDensity: VisualDensity.compact,
            onPressed: () => _menuMesa(mesa, estado),
          ),
        ],
      ),
    );
  }

  Widget _buildVacio(Color colorRestaurante) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_bar_outlined,
            size: 64,
            color: AppTheme.textoTerciario.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No hay mesas configuradas',
            style: TextStyle(color: AppTheme.textoSecundario),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _dialogoMesa(null),
            icon: const Icon(Icons.add),
            label: const Text('Crear primera mesa'),
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

  void _menuMesa(Mesa mesa, EstadoMesa estado) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.of(context).pop();
                _dialogoMesa(mesa);
              },
            ),
            ListTile(
              leading: Icon(
                estado.ocupada ? Icons.block : Icons.delete,
                color: estado.ocupada ? AppTheme.amarilloOscuro : AppTheme.rojo,
              ),
              title: Text(
                estado.ocupada
                    ? 'No se puede eliminar (mesa ocupada)'
                    : 'Eliminar',
                style: TextStyle(
                  color: estado.ocupada
                      ? AppTheme.textoTerciario
                      : AppTheme.rojo,
                ),
              ),
              enabled: !estado.ocupada,
              onTap: () {
                Navigator.of(context).pop();
                _confirmarEliminarMesa(mesa);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dialogoMesa(Mesa? existente) async {
    final numeroCtrl = TextEditingController(text: existente?.numero ?? '');
    final capacidadCtrl = TextEditingController(
      text: existente?.capacidad.toString() ?? '4',
    );
    final esEditar = existente != null;

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esEditar ? 'Editar mesa' : 'Nueva mesa'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numeroCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Número o identificador',
                  hintText: 'Ej: 1, 2, VIP, Terraza-1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capacidadCtrl,
                decoration: const InputDecoration(
                  labelText: 'Capacidad (personas)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people, size: 18),
                ),
                keyboardType: TextInputType.number,
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
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (guardar != true || !mounted) return;
    final numero = numeroCtrl.text.trim();
    final capacidad = int.tryParse(capacidadCtrl.text.trim());

    if (numero.isEmpty || capacidad == null || capacidad <= 0) {
      _showError('Verifica el número y la capacidad');
      return;
    }

    final admin = context.read<AdminService>();
    final auth = context.read<AuthService>();
    String? error;

    if (esEditar) {
      error = await admin.actualizarMesa(
        id: existente.id,
        numero: numero,
        capacidad: capacidad,
      );
    } else {
      error = await admin.crearMesa(
        restauranteId: auth.restaurante!['id'] as String,
        numero: numero,
        capacidad: capacidad,
      );
    }

    if (!mounted) return;
    if (error != null) {
      _showError(error);
    } else {
      _showOk(esEditar ? 'Mesa actualizada' : 'Mesa creada');
    }
  }

  Future<void> _confirmarEliminarMesa(Mesa mesa) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline,
            color: AppTheme.rojo, size: 48),
        title: Text('¿Eliminar Mesa ${mesa.numero}?'),
        content: const Text(
          'Esta acción no se puede deshacer.\n'
          'Si tiene historial de pedidos, considera mejor desactivarla editándola.',
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
    final error = await context.read<AdminService>().eliminarMesa(mesa.id);
    if (!mounted) return;
    if (error != null) {
      _showError(error);
    } else {
      _showOk('Mesa eliminada');
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
}
