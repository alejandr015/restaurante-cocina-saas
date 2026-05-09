import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';
import '../services/carrito_service.dart';

/// Pantalla del menú: muestra categorías y sus productos.
/// Permite agregar/quitar items del carrito tocando los botones.
/// Incluye un panel inferior con el resumen y botón "Ver carrito".
class MenuScreen extends StatefulWidget {
  final Color colorRestaurante;
  final VoidCallback onIrAlCarrito;

  const MenuScreen({
    super.key,
    required this.colorRestaurante,
    required this.onIrAlCarrito,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String? _categoriaActivaId;

  @override
  void initState() {
    super.initState();
    // Selecciona la primera categoría por defecto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cats = context.read<MenuService>().categorias;
      if (cats.isNotEmpty) {
        setState(() => _categoriaActivaId = cats.first.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuService>();

    if (menu.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (menu.categorias.isEmpty) {
      return _buildSinMenu();
    }

    // Si no hay categoría activa aún, usa la primera
    final categoriaId = _categoriaActivaId ?? menu.categorias.first.id;
    final productos = menu.productosDeCategoria(categoriaId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final esMobile = constraints.maxWidth < 700;
        return Column(
          children: [
            Expanded(
              child: esMobile
                  ? _buildVistaMobile(menu, categoriaId, productos)
                  : _buildVistaDesktop(menu, categoriaId, productos),
            ),
            _buildBarraCarrito(),
          ],
        );
      },
    );
  }

  // ---- Vista escritorio: categorías a la izquierda, productos a la derecha ----
  Widget _buildVistaDesktop(
    MenuService menu,
    String categoriaActivaId,
    List<Producto> productos,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar de categorías
          SizedBox(
            width: 200,
            child: _buildSidebarCategorias(menu, categoriaActivaId),
          ),
          const SizedBox(width: 10),
          // Productos
          Expanded(child: _buildGridProductos(productos)),
        ],
      ),
    );
  }

  // ---- Vista mobile: categorías como tabs scroll horizontal arriba ----
  Widget _buildVistaMobile(
    MenuService menu,
    String categoriaActivaId,
    List<Producto> productos,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: menu.categorias.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = menu.categorias[i];
              final activa = cat.id == categoriaActivaId;
              return GestureDetector(
                onTap: () => setState(() => _categoriaActivaId = cat.id),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: activa
                        ? widget.colorRestaurante
                        : AppTheme.superficie,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: activa
                          ? widget.colorRestaurante
                          : AppTheme.borde,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    cat.nombre,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: activa
                          ? Colors.white
                          : AppTheme.textoPrimario,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildGridProductos(productos),
          ),
        ),
      ],
    );
  }

  // ---- Sidebar de categorías (escritorio) ----
  Widget _buildSidebarCategorias(MenuService menu, String activaId) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: menu.categorias.length,
        itemBuilder: (context, i) {
          final cat = menu.categorias[i];
          final activa = cat.id == activaId;
          final cantidadProductos = menu.productosDeCategoria(cat.id).length;
          return InkWell(
            onTap: () => setState(() => _categoriaActivaId = cat.id),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
              decoration: BoxDecoration(
                color: activa
                    ? widget.colorRestaurante.withValues(alpha: 0.08)
                    : null,
                border: Border(
                  left: BorderSide(
                    color: activa ? widget.colorRestaurante : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      cat.nombre,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: activa ? FontWeight.w600 : FontWeight.w500,
                        color: activa
                            ? widget.colorRestaurante
                            : AppTheme.textoPrimario,
                      ),
                    ),
                  ),
                  Text(
                    '$cantidadProductos',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textoTerciario,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---- Grid de productos ----
  Widget _buildGridProductos(List<Producto> productos) {
    if (productos.isEmpty) {
      return const Center(
        child: Text(
          'Sin productos en esta categoría',
          style: TextStyle(color: AppTheme.textoSecundario),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth < 380
            ? 1
            : constraints.maxWidth < 700
                ? 2
                : constraints.maxWidth < 1100
                    ? 3
                    : 4;
        return GridView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: productos.length,
          itemBuilder: (context, i) => _buildTarjetaProducto(productos[i]),
        );
      },
    );
  }

  Widget _buildTarjetaProducto(Producto producto) {
    return Consumer<CarritoService>(
      builder: (context, carrito, _) {
        final cantidad = carrito.cantidadDe(producto);
        final enCarrito = cantidad > 0;
        final formato = NumberFormat('#,##0', 'es_CO');

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.superficie,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enCarrito ? widget.colorRestaurante : AppTheme.borde,
              width: enCarrito ? 1.5 : 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre y precio
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        producto.nombre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textoPrimario,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Descripción
                Expanded(
                  child: Text(
                    producto.descripcion ?? '',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textoSecundario,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                // Precio + acciones
                Row(
                  children: [
                    Text(
                      '\$${formato.format(producto.precio)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.colorRestaurante,
                      ),
                    ),
                    const Spacer(),
                    if (!enCarrito)
                      _BotonAgregar(
                        color: widget.colorRestaurante,
                        onPressed: () => carrito.agregarProducto(producto),
                      )
                    else
                      _ControlCantidad(
                        cantidad: cantidad,
                        color: widget.colorRestaurante,
                        onAgregar: () => carrito.agregarProducto(producto),
                        onQuitar: () => carrito.quitarProducto(producto),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- Barra inferior con resumen del carrito ----
  Widget _buildBarraCarrito() {
    return Consumer<CarritoService>(
      builder: (context, carrito, _) {
        if (carrito.vacio) return const SizedBox.shrink();

        final formato = NumberFormat('#,##0', 'es_CO');
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.colorRestaurante,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${carrito.cantidadTotal}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Carrito',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '\$${formato.format(carrito.total)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: widget.onIrAlCarrito,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: widget.colorRestaurante,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Ver carrito',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSinMenu() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: AppTheme.textoTerciario.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay menú configurado',
              style: TextStyle(fontSize: 16, color: AppTheme.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonAgregar extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;

  const _BotonAgregar({required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.add, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _ControlCantidad extends StatelessWidget {
  final int cantidad;
  final Color color;
  final VoidCallback onAgregar;
  final VoidCallback onQuitar;

  const _ControlCantidad({
    required this.cantidad,
    required this.color,
    required this.onAgregar,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, onQuitar),
          Container(
            constraints: const BoxConstraints(minWidth: 26),
            alignment: Alignment.center,
            child: Text(
              '$cantidad',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _btn(Icons.add, onAgregar),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
