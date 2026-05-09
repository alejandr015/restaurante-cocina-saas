import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import '../services/mesas_service.dart';
import '../services/carrito_service.dart';
import 'mesas_screen.dart';
import 'menu_screen.dart';
import 'carrito_screen.dart';
import 'cuenta_mesa_screen.dart';

/// Pantalla principal del mesero. Maneja navegación interna entre:
///   0. Selección de mesa
///   1. Cuenta de mesa (si ya está ocupada)
///   2. Menú (productos por categoría)
///   3. Carrito y confirmación
class MeseroScreen extends StatefulWidget {
  const MeseroScreen({super.key});

  @override
  State<MeseroScreen> createState() => _MeseroScreenState();
}

class _MeseroScreenState extends State<MeseroScreen> {
  /// 0=mesas, 1=cuenta_mesa, 2=menú, 3=carrito
  int _vistaActual = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuService>().cargar();
      context.read<MesasService>().inicializar();
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
        child: Column(
          children: [
            _buildBarraSuperior(context, r['nombre'] as String, colorRestaurante),
            Expanded(child: _buildContenido(colorRestaurante)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraSuperior(
    BuildContext context,
    String nombreRestaurante,
    Color colorRestaurante,
  ) {
    final carrito = context.watch<CarritoService>();
    final mostrandoMesas = _vistaActual == 0;

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
          if (!mostrandoMesas)
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: _navegarAtras,
              tooltip: 'Volver',
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorRestaurante.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.room_service, color: colorRestaurante, size: 20),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  carrito.mesa != null
                      ? 'Mesa ${carrito.mesa!.numero}'
                      : nombreRestaurante,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textoPrimario,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _subtituloBarra(carrito, nombreRestaurante),
                  style: const TextStyle(
                    fontSize: 12,
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
            onPressed: () async {
              context.read<MenuService>().limpiar();
              context.read<MesasService>().limpiar();
              context.read<CarritoService>().limpiar();
              await context.read<AuthService>().logout();
            },
          ),
        ],
      ),
    );
  }

  String _subtituloBarra(CarritoService carrito, String nombreRestaurante) {
    if (carrito.mesa == null) {
      return 'Mesero · $nombreRestaurante';
    }
    switch (_vistaActual) {
      case 1:
        return 'Cuenta abierta';
      case 2:
        return 'Eligiendo productos · ${carrito.cantidadTotal} en carrito';
      case 3:
        return 'Revisando carrito · ${carrito.cantidadTotal} ítem${carrito.cantidadTotal != 1 ? "s" : ""}';
      default:
        return nombreRestaurante;
    }
  }

  void _navegarAtras() {
    switch (_vistaActual) {
      case 3:
        // Del carrito al menú
        setState(() => _vistaActual = 2);
        break;
      case 2:
        // Del menú: si la mesa estaba ocupada, volver a cuenta de mesa
        // Si estaba libre (era pedido nuevo), volver a mesas
        final carrito = context.read<CarritoService>();
        final mesa = carrito.mesa;
        if (mesa != null) {
          final estado = context.read<MesasService>().estadoDe(mesa.numero);
          // Si la mesa tiene pedidos abiertos Y el carrito está vacío, va a cuenta
          if (estado.ocupada && carrito.vacio) {
            setState(() => _vistaActual = 1);
          } else {
            // Carrito tiene cosas o mesa nueva → ir a mesas (limpia carrito)
            context.read<CarritoService>().limpiar();
            setState(() => _vistaActual = 0);
          }
        } else {
          setState(() => _vistaActual = 0);
        }
        break;
      case 1:
        // De cuenta de mesa a mesas
        context.read<CarritoService>().deseleccionarMesa();
        setState(() => _vistaActual = 0);
        break;
    }
  }

  Widget _buildContenido(Color colorRestaurante) {
    switch (_vistaActual) {
      case 0:
        return MesasScreen(
          colorRestaurante: colorRestaurante,
          onMesaSeleccionada: (mesa, ocupada) {
            // Si la mesa está ocupada, ir a la cuenta. Si está libre, al menú.
            setState(() => _vistaActual = ocupada ? 1 : 2);
          },
        );
      case 1:
        return CuentaMesaScreen(
          colorRestaurante: colorRestaurante,
          onAgregarPedido: () => setState(() => _vistaActual = 2),
          onCuentaCerrada: () => setState(() => _vistaActual = 0),
        );
      case 2:
        return MenuScreen(
          colorRestaurante: colorRestaurante,
          onIrAlCarrito: () => setState(() => _vistaActual = 3),
        );
      case 3:
        return CarritoScreen(
          colorRestaurante: colorRestaurante,
          onVolverAlMenu: () => setState(() => _vistaActual = 2),
          onPedidoConfirmado: _despuesDeConfirmar,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Después de confirmar un pedido, vamos a la cuenta de la mesa
  /// (que ahora tendrá ese pedido recién agregado).
  void _despuesDeConfirmar() {
    final mesa = context.read<CarritoService>().mesa;
    if (mesa != null) {
      // El carrito se limpió en confirmarPedido, así que reseleccionamos la mesa
      // para mantenernos en su contexto
      // (la mesa también se limpió en el carrito service al confirmar)
    }
    // Volvemos a la pantalla de mesas para que el flujo sea: confirmar → ver mesas
    // El indicador rojo aparecerá automáticamente porque ahora hay pedido abierto
    setState(() => _vistaActual = 0);
  }
}
