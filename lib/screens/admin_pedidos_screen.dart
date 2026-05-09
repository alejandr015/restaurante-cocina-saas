import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/pedido.dart';
import '../services/auth_service.dart';
import '../services/historial_service.dart';

class AdminPedidosScreen extends StatefulWidget {
  const AdminPedidosScreen({super.key});

  @override
  State<AdminPedidosScreen> createState() => _AdminPedidosScreenState();
}

class _AdminPedidosScreenState extends State<AdminPedidosScreen> {
  final Set<int> _expandidos = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargar el rango "hoy" por defecto al entrar
      context.read<HistorialService>().setRango(RangoFecha.hoy);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final hist = context.watch<HistorialService>();
    final colorRestaurante =
        AppTheme.hexToColor(auth.restaurante!['color_primario'] as String);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(hist),
          const SizedBox(height: 12),
          _buildFiltros(hist, colorRestaurante),
          const SizedBox(height: 12),
          _buildResumen(hist, colorRestaurante),
          const SizedBox(height: 12),
          Expanded(child: _buildLista(hist, colorRestaurante)),
        ],
      ),
    );
  }

  Widget _buildHeader(HistorialService hist) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pedidos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textoPrimario,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Historial de pedidos del restaurante',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textoSecundario,
                ),
              ),
            ],
          ),
        ),
        if (hist.cargando)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => hist.cargar(),
            tooltip: 'Actualizar',
            color: AppTheme.textoSecundario,
          ),
      ],
    );
  }

  Widget _buildFiltros(HistorialService hist, Color colorRestaurante) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rango de fecha
          const Text(
            'Período',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textoSecundario,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RangoFecha.values.map((r) {
              final activo = hist.rangoActual == r;
              return _buildChip(
                label: r.label,
                activo: activo,
                color: colorRestaurante,
                onTap: () async {
                  if (r == RangoFecha.personalizado) {
                    await _seleccionarRangoPersonalizado(hist);
                  } else {
                    await hist.setRango(r);
                  }
                },
              );
            }).toList(),
          ),
          if (hist.rangoActual == RangoFecha.personalizado &&
              hist.fechaDesde != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event,
                    size: 14, color: AppTheme.textoTerciario),
                const SizedBox(width: 4),
                Text(
                  '${_fmtFecha(hist.fechaDesde!)}  →  ${_fmtFecha(hist.fechaHasta!.subtract(const Duration(days: 1)))}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textoTerciario,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borde),
          const SizedBox(height: 12),
          // Estado
          const Text(
            'Estado',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textoSecundario,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FiltroEstado.values.map((f) {
              final activo = hist.filtroEstado == f;
              return _buildChip(
                label: f.label,
                activo: activo,
                color: colorRestaurante,
                onTap: () => hist.setFiltroEstado(f),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool activo,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? color : AppTheme.fondo,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: activo ? color : AppTheme.borde,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: activo ? Colors.white : AppTheme.textoPrimario,
          ),
        ),
      ),
    );
  }

  Widget _buildResumen(HistorialService hist, Color colorRestaurante) {
    final formato = NumberFormat('#,##0', 'es_CO');
    return Row(
      children: [
        Expanded(
          child: _buildTarjetaResumen(
            label: 'Total ventas',
            valor: '\$${formato.format(hist.totalVentas)}',
            icono: Icons.payments,
            color: colorRestaurante,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTarjetaResumen(
            label: 'Pedidos cerrados',
            valor: '${hist.cantidadVentasCerradas}',
            icono: Icons.check_circle_outline,
            color: AppTheme.verde,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTarjetaResumen(
            label: 'Total registros',
            valor: '${hist.cantidadTotal}',
            icono: Icons.receipt_long,
            color: AppTheme.textoSecundario,
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaResumen({
    required String label,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textoSecundario,
                  ),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textoPrimario,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(HistorialService hist, Color colorRestaurante) {
    if (hist.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppTheme.rojo),
            const SizedBox(height: 12),
            Text(hist.error ?? 'Error', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (hist.cargando && hist.pedidos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hist.pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppTheme.textoTerciario.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay pedidos en este período',
              style: TextStyle(color: AppTheme.textoSecundario),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: hist.pedidos.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppTheme.borde),
        itemBuilder: (context, i) {
          final pedido = hist.pedidos[i];
          return _buildFilaPedido(pedido);
        },
      ),
    );
  }

  Widget _buildFilaPedido(Pedido pedido) {
    final expandido = _expandidos.contains(pedido.id);
    final formato = NumberFormat('#,##0', 'es_CO');
    final hora = DateFormat('HH:mm').format(pedido.createdAt);
    final fecha = DateFormat('dd MMM', 'es').format(pedido.createdAt);

    return InkWell(
      onTap: () => setState(() {
        if (expandido) {
          _expandidos.remove(pedido.id);
        } else {
          _expandidos.add(pedido.id);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: pedido.estado.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#${pedido.numeroPedido}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: pedido.estado.color,
                      ),
                    ),
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
                            pedido.ubicacionLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textoPrimario,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  pedido.estado.color.withValues(alpha: 0.15),
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
                        '$fecha · $hora · ${pedido.items.fold<int>(0, (sum, i) => sum + i.cantidad)} ítems',
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
                const SizedBox(width: 4),
                Icon(
                  expandido ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppTheme.textoTerciario,
                ),
              ],
            ),
            // Detalle expandible
            if (expandido) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.fondo,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pedido.clienteNombre.isNotEmpty) ...[
                      _filaDetalle('Cliente', pedido.clienteNombre),
                      const SizedBox(height: 4),
                    ],
                    if (pedido.notas != null && pedido.notas!.isNotEmpty) ...[
                      _filaDetalle('Notas', pedido.notas!,
                          color: AppTheme.amarilloOscuro),
                      const SizedBox(height: 4),
                    ],
                    const SizedBox(height: 6),
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...pedido.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 30,
                                child: Text(
                                  '${item.cantidad}×',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textoSecundario,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item.nombre,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textoPrimario,
                                  ),
                                ),
                              ),
                              Text(
                                '\$${formato.format(item.subtotal)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textoSecundario,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filaDetalle(String label, String valor, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textoSecundario,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            valor,
            style: TextStyle(
              fontSize: 12,
              color: color ?? AppTheme.textoPrimario,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarRangoPersonalizado(HistorialService hist) async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: hist.fechaDesde != null
          ? DateTimeRange(
              start: hist.fechaDesde!,
              end: hist.fechaHasta != null
                  ? hist.fechaHasta!.subtract(const Duration(days: 1))
                  : DateTime.now(),
            )
          : null,
    );

    if (rango != null) {
      await hist.setRango(
        RangoFecha.personalizado,
        desde: rango.start,
        hasta: rango.end,
      );
    }
  }

  String _fmtFecha(DateTime d) =>
      DateFormat('dd MMM yyyy', 'es').format(d);
}
