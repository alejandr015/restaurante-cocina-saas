import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/pedido.dart';
import '../services/auth_service.dart';
import '../services/historial_service.dart';

class AdminVentasScreen extends StatefulWidget {
  const AdminVentasScreen({super.key});

  @override
  State<AdminVentasScreen> createState() => _AdminVentasScreenState();
}

class _AdminVentasScreenState extends State<AdminVentasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Forzamos a "cerrados" porque solo eso cuenta como venta
      final hist = context.read<HistorialService>();
      hist.setFiltroEstado(FiltroEstado.cerrados);
      hist.setRango(RangoFecha.hoy);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final hist = context.watch<HistorialService>();
    final colorRestaurante =
        AppTheme.hexToColor(auth.restaurante!['color_primario'] as String);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(hist),
          const SizedBox(height: 12),
          _buildSelectorPeriodo(hist, colorRestaurante),
          const SizedBox(height: 16),
          _buildKpis(hist, colorRestaurante),
          const SizedBox(height: 16),
          _buildProductosTop(hist, colorRestaurante),
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
                'Ventas',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textoPrimario,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Métricas y productos más vendidos',
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

  Widget _buildSelectorPeriodo(HistorialService hist, Color colorRestaurante) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.event,
              size: 16, color: AppTheme.textoSecundario),
          const SizedBox(width: 8),
          const Text(
            'Período:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textoSecundario,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RangoFecha.values.map((r) {
                final activo = hist.rangoActual == r;
                return GestureDetector(
                  onTap: () async {
                    if (r == RangoFecha.personalizado) {
                      await _seleccionarRangoPersonalizado(hist);
                    } else {
                      await hist.setRango(r);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: activo ? colorRestaurante : AppTheme.fondo,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: activo ? colorRestaurante : AppTheme.borde,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      r.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            activo ? Colors.white : AppTheme.textoPrimario,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpis(HistorialService hist, Color colorRestaurante) {
    final ventas = hist.totalVentas;
    final cantidad = hist.cantidadVentasCerradas;
    final ticketPromedio = cantidad > 0 ? ventas / cantidad : 0.0;
    final formato = NumberFormat('#,##0', 'es_CO');

    return LayoutBuilder(
      builder: (context, constraints) {
        final esMobile = constraints.maxWidth < 700;
        final children = [
          Expanded(
            child: _Kpi(
              label: 'Total ventas',
              valor: '\$${formato.format(ventas)}',
              icono: Icons.payments,
              color: colorRestaurante,
              destacado: true,
            ),
          ),
          SizedBox(
            width: esMobile ? double.infinity : 12,
            height: esMobile ? 12 : 0,
          ),
          Expanded(
            child: _Kpi(
              label: 'Pedidos',
              valor: '$cantidad',
              icono: Icons.receipt_long,
              color: AppTheme.verde,
            ),
          ),
          SizedBox(
            width: esMobile ? double.infinity : 12,
            height: esMobile ? 12 : 0,
          ),
          Expanded(
            child: _Kpi(
              label: 'Ticket promedio',
              valor: '\$${formato.format(ticketPromedio)}',
              icono: Icons.trending_up,
              color: AppTheme.amarilloOscuro,
            ),
          ),
        ];

        return esMobile
            ? Column(
                children: children
                    .map((c) => c is Expanded ? c.child : c)
                    .toList())
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
      },
    );
  }

  Widget _buildProductosTop(HistorialService hist, Color colorRestaurante) {
    final ranking = _calcularRanking(hist.pedidos);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_outline,
                    size: 18, color: colorRestaurante),
                const SizedBox(width: 8),
                const Text(
                  'Productos más vendidos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textoPrimario,
                  ),
                ),
                const Spacer(),
                Text(
                  '${ranking.length} producto${ranking.length != 1 ? "s" : ""}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textoSecundario,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (ranking.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 40,
                        color:
                            AppTheme.textoTerciario.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No hay ventas en este período',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._buildBarrasRanking(ranking, colorRestaurante),
          ],
        ),
      ),
    );
  }

  /// Calcula ranking de productos por cantidad vendida (solo pedidos cerrados)
  List<_RankingProducto> _calcularRanking(List<Pedido> pedidos) {
    final mapa = <String, _RankingProducto>{};

    for (final p in pedidos) {
      if (p.estado != EstadoPedido.cerrado) continue;
      for (final item in p.items) {
        if (mapa.containsKey(item.nombre)) {
          mapa[item.nombre]!.cantidad += item.cantidad;
          mapa[item.nombre]!.ingreso += item.subtotal;
        } else {
          mapa[item.nombre] = _RankingProducto(
            nombre: item.nombre,
            cantidad: item.cantidad,
            ingreso: item.subtotal,
          );
        }
      }
    }

    final lista = mapa.values.toList()
      ..sort((a, b) => b.cantidad.compareTo(a.cantidad));

    return lista.take(10).toList();
  }

  List<Widget> _buildBarrasRanking(
    List<_RankingProducto> ranking,
    Color colorRestaurante,
  ) {
    final cantidadMaxima = ranking.first.cantidad;
    final formato = NumberFormat('#,##0', 'es_CO');

    return List.generate(ranking.length, (i) {
      final p = ranking[i];
      final porcentaje = p.cantidad / cantidadMaxima;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i < 3
                        ? colorRestaurante.withValues(alpha: 0.15)
                        : AppTheme.fondo,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: i < 3
                          ? colorRestaurante
                          : AppTheme.textoSecundario,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.nombre,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textoPrimario,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${p.cantidad} und',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textoPrimario,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    '\$${formato.format(p.ingreso)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: porcentaje,
                minHeight: 6,
                backgroundColor: AppTheme.fondo,
                valueColor: AlwaysStoppedAnimation<Color>(
                  i == 0
                      ? colorRestaurante
                      : colorRestaurante.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      );
    });
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
}

/// Tarjeta de KPI
class _Kpi extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;
  final Color color;
  final bool destacado;

  const _Kpi({
    required this.label,
    required this.valor,
    required this.icono,
    required this.color,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: destacado ? color.withValues(alpha: 0.08) : AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: destacado ? color.withValues(alpha: 0.3) : AppTheme.borde,
          width: destacado ? 1 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textoSecundario,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textoPrimario,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Helper interno para ranking de productos
class _RankingProducto {
  final String nombre;
  int cantidad;
  double ingreso;

  _RankingProducto({
    required this.nombre,
    required this.cantidad,
    required this.ingreso,
  });
}
