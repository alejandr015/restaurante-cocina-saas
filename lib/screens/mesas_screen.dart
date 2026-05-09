import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';
import '../services/carrito_service.dart';
import '../services/mesas_service.dart';

/// Pantalla de selección de mesa con indicadores de ocupación.
/// - Mesa libre: fondo claro, ícono color del restaurante
/// - Mesa ocupada: fondo rojo claro, badge con tiempo y total
class MesasScreen extends StatelessWidget {
  final Color colorRestaurante;
  final void Function(Mesa mesa, bool ocupada) onMesaSeleccionada;

  const MesasScreen({
    super.key,
    required this.colorRestaurante,
    required this.onMesaSeleccionada,
  });

  @override
  Widget build(BuildContext context) {
    final menuService = context.watch<MenuService>();
    final mesasService = context.watch<MesasService>();

    if (menuService.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (menuService.error != null) {
      return _buildError(menuService);
    }

    if (menuService.mesas.isEmpty) {
      return _buildSinMesas();
    }

    return _buildGrid(context, menuService.mesas, mesasService);
  }

  Widget _buildGrid(
    BuildContext context,
    List<Mesa> mesas,
    MesasService mesasService,
  ) {
    final ocupadas = mesas
        .where((m) => mesasService.estadoDe(m.numero).ocupada)
        .length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona una mesa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textoPrimario,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${mesas.length} mesas · $ocupadas ocupada${ocupadas != 1 ? "s" : ""}',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textoSecundario,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth < 500
                    ? 3
                    : constraints.maxWidth < 900
                        ? 4
                        : 6;
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: mesas.length,
                  itemBuilder: (context, i) =>
                      _buildTarjetaMesa(context, mesas[i], mesasService),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaMesa(
    BuildContext context,
    Mesa mesa,
    MesasService mesasService,
  ) {
    final estado = mesasService.estadoDe(mesa.numero);
    final ocupada = estado.ocupada;

    return Material(
      color: ocupada ? AppTheme.rojoFondo : AppTheme.superficie,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.read<CarritoService>().seleccionarMesa(mesa);
          onMesaSeleccionada(mesa, ocupada);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ocupada ? AppTheme.rojo : AppTheme.borde,
              width: ocupada ? 1.5 : 0.5,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              // Badge de tiempo en esquina superior derecha si está ocupada
              if (ocupada)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.rojo,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      estado.tiempoOcupada,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              // Contenido principal centrado
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_restaurant,
                      size: 28,
                      color: ocupada ? AppTheme.rojo : colorRestaurante,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mesa.numero.length > 3
                          ? mesa.numero
                          : 'Mesa ${mesa.numero}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ocupada
                            ? AppTheme.rojoOscuro
                            : AppTheme.textoPrimario,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    if (ocupada)
                      Text(
                        '${estado.cantidadItems} ítem${estado.cantidadItems != 1 ? "s" : ""}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.rojoOscuro,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        '${mesa.capacidad} 👤',
                        style: const TextStyle(
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
      ),
    );
  }

  Widget _buildError(MenuService menuService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.rojo),
            const SizedBox(height: 16),
            Text(
              menuService.error ?? 'Error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => menuService.cargar(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinMesas() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_bar_outlined,
              size: 64,
              color: AppTheme.textoTerciario.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay mesas configuradas',
              style: TextStyle(fontSize: 16, color: AppTheme.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}
