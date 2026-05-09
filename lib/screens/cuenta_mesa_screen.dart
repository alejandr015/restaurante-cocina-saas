import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/pedido.dart';
import '../services/mesas_service.dart';
import '../services/carrito_service.dart';

/// Pantalla que muestra la "cuenta abierta" de una mesa con todos
/// sus pedidos activos. Permite agregar más pedidos o cerrar la cuenta.
class CuentaMesaScreen extends StatelessWidget {
  final Color colorRestaurante;
  final VoidCallback onAgregarPedido;
  final VoidCallback onCuentaCerrada;

  const CuentaMesaScreen({
    super.key,
    required this.colorRestaurante,
    required this.onAgregarPedido,
    required this.onCuentaCerrada,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<MesasService, CarritoService>(
      builder: (context, mesasService, carritoService, _) {
        final mesa = carritoService.mesa;
        if (mesa == null) {
          return const Center(child: Text('No hay mesa seleccionada'));
        }

        final estado = mesasService.estadoDe(mesa.numero);

        if (!estado.ocupada) {
          // No debería pasar, pero por si acaso
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 64,
                  color: AppTheme.textoTerciario,
                ),
                const SizedBox(height: 16),
                Text('La Mesa ${mesa.numero} no tiene pedidos abiertos'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onAgregarPedido,
                  icon: const Icon(Icons.add),
                  label: const Text('Tomar pedido'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorRestaurante,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final esMobile = constraints.maxWidth < 700;
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: esMobile
                  ? _buildVistaMobile(context, mesasService, estado)
                  : _buildVistaDesktop(context, mesasService, estado),
            );
          },
        );
      },
    );
  }

  Widget _buildVistaDesktop(
    BuildContext context,
    MesasService mesasService,
    EstadoMesa estado,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildListaPedidos(estado)),
        const SizedBox(width: 10),
        SizedBox(
          width: 320,
          child: _buildPanelResumen(context, mesasService, estado),
        ),
      ],
    );
  }

  Widget _buildVistaMobile(
    BuildContext context,
    MesasService mesasService,
    EstadoMesa estado,
  ) {
    return Column(
      children: [
        Expanded(child: _buildListaPedidos(estado)),
        const SizedBox(height: 8),
        _buildPanelResumen(context, mesasService, estado),
      ],
    );
  }

  Widget _buildListaPedidos(EstadoMesa estado) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(
                  'Cuenta Mesa ${estado.numeroMesa}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textoPrimario,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.rojoFondo,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '⏱  ${estado.tiempoOcupada}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.rojoOscuro,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borde),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: estado.pedidosAbiertos.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.borde),
              itemBuilder: (context, i) =>
                  _buildPedidoFila(estado.pedidosAbiertos[i], i + 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidoFila(Pedido pedido, int numero) {
    final formato = NumberFormat('#,##0', 'es_CO');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: pedido.estado.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    '$numero',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: pedido.estado.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Pedido #${pedido.numeroPedido}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textoPrimario,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: pedido.estado.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            pedido.estado.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: pedido.estado.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'hace ${pedido.tiempoFormateado}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textoTerciario,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${formato.format(pedido.total ?? 0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textoPrimario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Items del pedido
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: pedido.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${item.cantidad}× ${item.nombre}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textoSecundario,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          // Notas si las hay
          if (pedido.notas != null && pedido.notas!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.amarilloFondo,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 12,
                      color: AppTheme.amarilloOscuro,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pedido.notas!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.amarilloOscuro,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPanelResumen(
    BuildContext context,
    MesasService mesasService,
    EstadoMesa estado,
  ) {
    final formato = NumberFormat('#,##0', 'es_CO');
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Resumen de la cuenta',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textoPrimario,
              ),
            ),
            const SizedBox(height: 12),
            _filaResumen(
                'Pedidos', '${estado.pedidosAbiertos.length}'),
            _filaResumen('Items totales', '${estado.cantidadItems}'),
            _filaResumen('Tiempo ocupada', estado.tiempoOcupada),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.borde),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textoPrimario,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${formato.format(estado.totalCuenta)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colorRestaurante,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onAgregarPedido,
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Agregar al pedido',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorRestaurante,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _confirmarCierre(context, mesasService, estado),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text(
                  'Cerrar cuenta',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.verde,
                  side: const BorderSide(color: AppTheme.verde, width: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaResumen(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textoSecundario,
            ),
          ),
          const Spacer(),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textoPrimario,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarCierre(
    BuildContext context,
    MesasService mesasService,
    EstadoMesa estado,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(
          Icons.help_outline,
          color: AppTheme.amarillo,
          size: 48,
        ),
        title: Text('Cerrar cuenta de Mesa ${estado.numeroMesa}?'),
        content: const Text(
          'Esto liberará la mesa para el siguiente cliente. '
          'Los pedidos quedarán archivados como cerrados.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.verde,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, cerrar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    if (!context.mounted) return;

    final error = await mesasService.cerrarCuentaMesa(estado.numeroMesa);
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.rojo),
      );
    } else {
      // Limpiar la mesa del carrito y volver a la lista de mesas
      context.read<CarritoService>().deseleccionarMesa();
      onCuentaCerrada();
    }
  }
}
