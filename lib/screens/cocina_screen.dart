import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/pedido.dart';
import '../services/auth_service.dart';
import '../services/pedidos_service.dart';
import '../widgets/tarjeta_pedido.dart';

/// Pantalla principal de cocina.
///
/// Es responsive:
/// - Pantallas anchas (>= 700px): tablero Kanban de 3 columnas lado a lado
/// - Pantallas angostas (< 700px): tabs (Nuevos / Cocinando / Listos)
class CocinaScreen extends StatefulWidget {
  const CocinaScreen({super.key});

  @override
  State<CocinaScreen> createState() => _CocinaScreenState();
}

class _CocinaScreenState extends State<CocinaScreen> {
  static const double _breakpointMobile = 700;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PedidosService>().inicializar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final r = auth.restaurante!;
    final colorRestaurante = AppTheme.hexToColor(r['color_primario'] as String);

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      body: SafeArea(
        child: Consumer<PedidosService>(
          builder: (context, service, _) {
            return Column(
              children: [
                _buildBarraSuperior(
                  context,
                  service,
                  r['nombre'] as String,
                  colorRestaurante,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final esMobile = constraints.maxWidth < _breakpointMobile;
                      return _buildContenido(
                        service,
                        colorRestaurante,
                        esMobile: esMobile,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---- Barra superior ----

  Widget _buildBarraSuperior(
    BuildContext context,
    PedidosService service,
    String nombreRestaurante,
    Color colorRestaurante,
  ) {
    final totalActivos = service.pedidos.length;
    final esMobile = MediaQuery.of(context).size.width < _breakpointMobile;

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
              color: colorRestaurante.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.restaurant_menu,
                color: colorRestaurante,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esMobile ? nombreRestaurante : 'Cocina · $nombreRestaurante',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textoPrimario,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$totalActivos activo${totalActivos != 1 ? "s" : ""} · ${service.conectado ? "en vivo" : "desconectado"}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textoSecundario,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // En mobile mostramos solo un ícono compacto en lugar del badge largo
          if (esMobile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                service.conectado ? Icons.wifi : Icons.wifi_off,
                size: 18,
                color: service.conectado ? AppTheme.verde : AppTheme.rojo,
              ),
            )
          else
            _buildBadgeConexion(service),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Cerrar sesión',
            color: AppTheme.textoSecundario,
            onPressed: () async {
              await context.read<PedidosService>().limpiar();
              if (context.mounted) {
                await context.read<AuthService>().logout();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeConexion(PedidosService service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: service.conectado ? AppTheme.verdeFondo : AppTheme.rojoFondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: service.conectado ? AppTheme.verde : AppTheme.rojo,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            service.conectado ? 'Conectado' : 'Desconectado',
            style: TextStyle(
              fontSize: 12,
              color: service.conectado
                  ? AppTheme.verdeOscuro
                  : AppTheme.rojoOscuro,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Contenido (responsive) ----

  Widget _buildContenido(
    PedidosService service,
    Color colorRestaurante, {
    required bool esMobile,
  }) {
    if (service.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (service.error != null && service.pedidos.isEmpty) {
      return _buildError(service);
    }

    if (esMobile) {
      return _buildVistaMobile(service, colorRestaurante);
    }
    return _buildVistaDesktop(service, colorRestaurante);
  }

  // ---- Vista escritorio (Kanban) ----

  Widget _buildVistaDesktop(PedidosService service, Color colorRestaurante) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildColumna(
              titulo: 'Nuevos',
              pedidos: service.pedidosNuevos,
              colorBadgeFondo: AppTheme.rojoFondo,
              colorBadgeTexto: AppTheme.rojoOscuro,
              colorRestaurante: colorRestaurante,
              onAccion: (id) => service.aceptarPedido(id),
              onCancelar: (id) => service.cancelarPedido(id),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildColumna(
              titulo: 'En preparación',
              pedidos: service.pedidosEnPreparacion,
              colorBadgeFondo: AppTheme.amarilloFondo,
              colorBadgeTexto: AppTheme.amarilloOscuro,
              colorRestaurante: colorRestaurante,
              onAccion: (id) => service.marcarListo(id),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildColumna(
              titulo: 'Listos',
              pedidos: service.pedidosListos,
              colorBadgeFondo: AppTheme.verdeFondo,
              colorBadgeTexto: AppTheme.verdeOscuro,
              colorRestaurante: colorRestaurante,
              onAccion: (id) => service.marcarEntregado(id),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Vista mobile (Tabs) ----

  Widget _buildVistaMobile(PedidosService service, Color colorRestaurante) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            decoration: BoxDecoration(
              color: AppTheme.superficie,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borde, width: 0.5),
            ),
            child: TabBar(
              labelColor: colorRestaurante,
              unselectedLabelColor: AppTheme.textoSecundario,
              indicatorColor: colorRestaurante,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: [
                Tab(text: 'Nuevos (${service.pedidosNuevos.length})'),
                Tab(text: 'Cocinando (${service.pedidosEnPreparacion.length})'),
                Tab(text: 'Listos (${service.pedidosListos.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildListaMobile(
                  service.pedidosNuevos,
                  colorRestaurante,
                  onAccion: (id) => service.aceptarPedido(id),
                  onCancelar: (id) => service.cancelarPedido(id),
                ),
                _buildListaMobile(
                  service.pedidosEnPreparacion,
                  colorRestaurante,
                  onAccion: (id) => service.marcarListo(id),
                ),
                _buildListaMobile(
                  service.pedidosListos,
                  colorRestaurante,
                  onAccion: (id) => service.marcarEntregado(id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaMobile(
    List<Pedido> pedidos,
    Color colorRestaurante, {
    required Function(int) onAccion,
    Function(int)? onCancelar,
  }) {
    if (pedidos.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: pedidos.length,
      itemBuilder: (context, i) => TarjetaPedido(
        pedido: pedidos[i],
        colorRestaurante: colorRestaurante,
        onAccion: () => onAccion(pedidos[i].id),
        onCancelar: onCancelar != null ? () => onCancelar(pedidos[i].id) : null,
      ),
    );
  }

  // ---- Columna del Kanban ----

  Widget _buildColumna({
    required String titulo,
    required List<Pedido> pedidos,
    required Color colorBadgeFondo,
    required Color colorBadgeTexto,
    required Color colorRestaurante,
    required Function(int) onAccion,
    Function(int)? onCancelar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textoPrimario,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorBadgeFondo,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${pedidos.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorBadgeTexto,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: pedidos.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: pedidos.length,
                  itemBuilder: (context, i) => TarjetaPedido(
                    pedido: pedidos[i],
                    colorRestaurante: colorRestaurante,
                    onAccion: () => onAccion(pedidos[i].id),
                    onCancelar: onCancelar != null
                        ? () => onCancelar(pedidos[i].id)
                        : null,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 40,
            color: AppTheme.textoTerciario.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sin pedidos',
            style: TextStyle(fontSize: 12, color: AppTheme.textoTerciario),
          ),
        ],
      ),
    );
  }

  Widget _buildError(PedidosService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.rojo),
            const SizedBox(height: 16),
            Text(
              service.error ?? 'Error desconocido',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => service.reconectar(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
