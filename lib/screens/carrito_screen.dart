import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/menu_models.dart';
import '../services/auth_service.dart';
import '../services/carrito_service.dart';

/// Pantalla del carrito: revisar items, agregar notas y confirmar pedido.
/// Al confirmar, se inserta en Supabase y aparece automáticamente
/// en la pantalla de cocina por Realtime.
class CarritoScreen extends StatefulWidget {
  final Color colorRestaurante;
  final VoidCallback onVolverAlMenu;
  final VoidCallback onPedidoConfirmado;

  const CarritoScreen({
    super.key,
    required this.colorRestaurante,
    required this.onVolverAlMenu,
    required this.onPedidoConfirmado,
  });

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final _nombreCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    final carrito = context.read<CarritoService>();
    _nombreCtrl.text = carrito.nombreCliente ?? '';
    _notasCtrl.text = carrito.notasGenerales ?? '';
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final auth = context.read<AuthService>();
    final carrito = context.read<CarritoService>();
    final restauranteId = auth.restaurante!['id'] as String;

    // Guardar nombre y notas en el carrito
    carrito.setNombreCliente(_nombreCtrl.text);
    carrito.setNotasGenerales(_notasCtrl.text);

    setState(() => _enviando = true);
    final error = await carrito.confirmarPedido(restauranteId: restauranteId);
    if (!mounted) return;
    setState(() => _enviando = false);

    if (error == null) {
      // Pedido enviado con éxito
      _mostrarExito();
    } else {
      _mostrarError(error);
    }
  }

  void _mostrarExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.check_circle, color: AppTheme.verde, size: 56),
        title: const Text(
          '¡Pedido enviado!',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'El pedido ya está en cocina.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onPedidoConfirmado();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.colorRestaurante,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tomar otro pedido'),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.rojo,
        content: Text(mensaje),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CarritoService>(
      builder: (context, carrito, _) {
        if (carrito.vacio) {
          return _buildVacio();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final esMobile = constraints.maxWidth < 700;
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: esMobile
                  ? _buildVistaMobile(carrito)
                  : _buildVistaDesktop(carrito),
            );
          },
        );
      },
    );
  }

  // ---- Vista escritorio: items a la izquierda, resumen a la derecha ----
  Widget _buildVistaDesktop(CarritoService carrito) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildListaItems(carrito)),
        const SizedBox(width: 10),
        SizedBox(width: 320, child: _buildPanelResumen(carrito)),
      ],
    );
  }

  // ---- Vista mobile: lista arriba, resumen abajo ----
  Widget _buildVistaMobile(CarritoService carrito) {
    return Column(
      children: [
        Expanded(child: _buildListaItems(carrito)),
        const SizedBox(height: 8),
        _buildPanelResumen(carrito),
      ],
    );
  }

  // ---- Lista de items en el carrito ----
  Widget _buildListaItems(CarritoService carrito) {
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
                  'Pedido · Mesa ${carrito.mesa?.numero ?? ""}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textoPrimario,
                  ),
                ),
                const Spacer(),
                Text(
                  '${carrito.cantidadTotal} ítem${carrito.cantidadTotal != 1 ? "s" : ""}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borde),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: carrito.items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.borde),
              itemBuilder: (context, i) =>
                  _buildItemFila(carrito, carrito.items[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemFila(CarritoService carrito, ItemCarrito item) {
    final formato = NumberFormat('#,##0', 'es_CO');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.producto.nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textoPrimario,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${formato.format(item.producto.precio)} c/u',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textoTerciario,
                  ),
                ),
              ],
            ),
          ),
          // Control - N +
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borde, width: 0.5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: () => carrito.quitarProducto(item.producto),
                  visualDensity: VisualDensity.compact,
                  color: AppTheme.textoSecundario,
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${item.cantidad}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textoPrimario,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: () => carrito.agregarProducto(item.producto),
                  visualDensity: VisualDensity.compact,
                  color: widget.colorRestaurante,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Subtotal
          SizedBox(
            width: 80,
            child: Text(
              '\$${formato.format(item.subtotal)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textoPrimario,
              ),
            ),
          ),
          // Botón eliminar
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => carrito.eliminarProducto(item.producto),
            visualDensity: VisualDensity.compact,
            color: AppTheme.textoTerciario,
            tooltip: 'Quitar del pedido',
          ),
        ],
      ),
    );
  }

  // ---- Panel derecho: resumen, datos del cliente y confirmar ----
  Widget _buildPanelResumen(CarritoService carrito) {
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
              'Detalles del pedido',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textoPrimario,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nombreCtrl,
              enabled: !_enviando,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente (opcional)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notasCtrl,
              enabled: !_enviando,
              decoration: const InputDecoration(
                labelText: 'Notas (ej: sin cebolla)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppTheme.borde),
            const SizedBox(height: 12),
            // Total
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
                  '\$${formato.format(carrito.total)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: widget.colorRestaurante,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Botón confirmar
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _enviando ? null : _confirmar,
                icon: _enviando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label: Text(
                  _enviando ? 'Enviando...' : 'Confirmar pedido',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.colorRestaurante,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: TextButton.icon(
                onPressed: _enviando ? null : widget.onVolverAlMenu,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar más productos'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textoSecundario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppTheme.textoTerciario.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Carrito vacío',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textoPrimario,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vuelve al menú para agregar productos',
              style: TextStyle(fontSize: 13, color: AppTheme.textoSecundario),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onVolverAlMenu,
              icon: const Icon(Icons.menu_book),
              label: const Text('Volver al menú'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.colorRestaurante,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
