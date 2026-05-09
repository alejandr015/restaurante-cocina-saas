import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/mesas_service.dart';
import 'admin_info_screen.dart';
import 'admin_menu_screen.dart';
import 'admin_mesas_screen.dart';
import 'admin_pedidos_screen.dart';
import 'admin_ventas_screen.dart';
import 'admin_usuarios_screen.dart';
import 'cocina_screen.dart';

enum SeccionAdmin {
  info,
  menu,
  mesas,
  usuarios,
  pedidos,
  ventas,
  cocina;

  String get label {
    switch (this) {
      case SeccionAdmin.info:
        return 'Restaurante';
      case SeccionAdmin.menu:
        return 'Menú';
      case SeccionAdmin.mesas:
        return 'Mesas';
      case SeccionAdmin.usuarios:
        return 'Usuarios';
      case SeccionAdmin.pedidos:
        return 'Pedidos';
      case SeccionAdmin.ventas:
        return 'Ventas';
      case SeccionAdmin.cocina:
        return 'Cocina (Kanban)';
    }
  }

  IconData get icono {
    switch (this) {
      case SeccionAdmin.info:
        return Icons.storefront;
      case SeccionAdmin.menu:
        return Icons.menu_book;
      case SeccionAdmin.mesas:
        return Icons.table_restaurant;
      case SeccionAdmin.usuarios:
        return Icons.people_outline;
      case SeccionAdmin.pedidos:
        return Icons.receipt_long;
      case SeccionAdmin.ventas:
        return Icons.bar_chart;
      case SeccionAdmin.cocina:
        return Icons.soup_kitchen;
    }
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  SeccionAdmin _seccion = SeccionAdmin.info;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MesasService>().inicializar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final r = auth.restaurante!;
    final colorRestaurante = AppTheme.hexToColor(r['color_primario'] as String);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.fondo,
      drawer: Drawer(
        backgroundColor: AppTheme.superficie,
        child: _buildSidebar(r, colorRestaurante),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(r, colorRestaurante),
            Expanded(child: _buildContenido(colorRestaurante)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(Map<String, dynamic> r, Color colorRestaurante) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, size: 22),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'Menú',
            color: AppTheme.textoPrimario,
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorRestaurante.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_seccion.icono, color: colorRestaurante, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _seccion.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textoPrimario,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${r['nombre']}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textoSecundario,
                  ),
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildSidebar(Map<String, dynamic> r, Color colorRestaurante) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.borde, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorRestaurante.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.storefront,
                  color: colorRestaurante,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['nombre'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textoPrimario,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Panel Admin',
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
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: SeccionAdmin.values
                .map((s) => _buildItemSidebar(s, colorRestaurante))
                .toList(),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.borde, width: 0.5),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthService>().logout();
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Cerrar sesión'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textoSecundario,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemSidebar(SeccionAdmin seccion, Color colorRestaurante) {
    final activa = _seccion == seccion;
    return InkWell(
      onTap: () {
        setState(() => _seccion = seccion);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: activa ? colorRestaurante.withValues(alpha: 0.08) : null,
          border: Border(
            left: BorderSide(
              color: activa ? colorRestaurante : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              seccion.icono,
              size: 18,
              color: activa ? colorRestaurante : AppTheme.textoSecundario,
            ),
            const SizedBox(width: 12),
            Text(
              seccion.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: activa ? FontWeight.w600 : FontWeight.w500,
                color: activa ? colorRestaurante : AppTheme.textoPrimario,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido(Color colorRestaurante) {
    switch (_seccion) {
      case SeccionAdmin.info:
        return const AdminInfoScreen();
      case SeccionAdmin.menu:
        return const AdminMenuScreen();
      case SeccionAdmin.mesas:
        return const AdminMesasScreen();
      case SeccionAdmin.pedidos:
        return const AdminPedidosScreen();
      case SeccionAdmin.ventas:
        return const AdminVentasScreen();
      case SeccionAdmin.usuarios:
        return const AdminUsuariosScreen();
      case SeccionAdmin.cocina:
        return const CocinaScreen();
    }
  }
}
