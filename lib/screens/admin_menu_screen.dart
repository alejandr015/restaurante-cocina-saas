import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/menu_models.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import '../services/admin_service.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  String? _categoriaActivaId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Siempre llamamos a cargar(); internamente el servicio
      // no se vuelve a suscribir a Realtime si ya está suscrito.
      context.read<MenuService>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final menu = context.watch<MenuService>();
    final colorRestaurante =
        AppTheme.hexToColor(auth.restaurante!['color_primario'] as String);

    if (menu.cargando && menu.categorias.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final categorias = menu.categorias;
    final categoriaActiva = categorias.isNotEmpty
        ? categorias.firstWhere(
            (c) => c.id == _categoriaActivaId,
            orElse: () => categorias.first,
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final esMobile = constraints.maxWidth < 700;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: esMobile
              ? _buildVistaMobile(menu, categoriaActiva, colorRestaurante)
              : _buildVistaDesktop(menu, categoriaActiva, colorRestaurante),
        );
      },
    );
  }

  Widget _buildVistaDesktop(
    MenuService menu,
    Categoria? categoriaActiva,
    Color colorRestaurante,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 280,
          child: _buildPanelCategorias(menu, categoriaActiva, colorRestaurante),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPanelProductos(menu, categoriaActiva, colorRestaurante),
        ),
      ],
    );
  }

  Widget _buildVistaMobile(
    MenuService menu,
    Categoria? categoriaActiva,
    Color colorRestaurante,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: menu.categorias.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = menu.categorias[i];
                    final activa = cat.id == categoriaActiva?.id;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _categoriaActivaId = cat.id),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: activa
                              ? colorRestaurante
                              : AppTheme.superficie,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: activa ? colorRestaurante : AppTheme.borde,
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
              IconButton(
                icon: const Icon(Icons.add_circle, size: 28),
                color: colorRestaurante,
                onPressed: () => _dialogoCategoria(null),
                tooltip: 'Nueva categoría',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildPanelProductos(menu, categoriaActiva, colorRestaurante),
        ),
      ],
    );
  }

  Widget _buildPanelCategorias(
    MenuService menu,
    Categoria? activa,
    Color colorRestaurante,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textoPrimario,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 22),
                  color: colorRestaurante,
                  onPressed: () => _dialogoCategoria(null),
                  tooltip: 'Nueva categoría',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borde),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: menu.categorias.length,
              itemBuilder: (context, i) {
                final cat = menu.categorias[i];
                final esActiva = cat.id == activa?.id;
                final productos = menu.productosDeCategoria(cat.id).length;
                return InkWell(
                  onTap: () => setState(() => _categoriaActivaId = cat.id),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    decoration: BoxDecoration(
                      color: esActiva
                          ? colorRestaurante.withValues(alpha: 0.08)
                          : null,
                      border: Border(
                        left: BorderSide(
                          color: esActiva
                              ? colorRestaurante
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.nombre,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: esActiva
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: esActiva
                                      ? colorRestaurante
                                      : AppTheme.textoPrimario,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$productos producto${productos != 1 ? "s" : ""}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textoTerciario,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 18),
                          color: AppTheme.textoSecundario,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _menuCategoria(cat),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelProductos(
    MenuService menu,
    Categoria? categoriaActiva,
    Color colorRestaurante,
  ) {
    if (categoriaActiva == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: AppTheme.textoTerciario.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay categorías. Crea la primera.',
              style: TextStyle(color: AppTheme.textoSecundario),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _dialogoCategoria(null),
              icon: const Icon(Icons.add),
              label: const Text('Nueva categoría'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorRestaurante,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final productos = menu.productosDeCategoria(categoriaActiva.id);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borde, width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoriaActiva.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textoPrimario,
                        ),
                      ),
                      Text(
                        '${productos.length} producto${productos.length != 1 ? "s" : ""}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      _dialogoProducto(null, categoriaActiva),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Nuevo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorRestaurante,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borde),
          Expanded(
            child: productos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fastfood_outlined,
                          size: 48,
                          color:
                              AppTheme.textoTerciario.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No hay productos en esta categoría',
                          style: TextStyle(
                            color: AppTheme.textoSecundario,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: productos.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppTheme.borde),
                    itemBuilder: (context, i) =>
                        _buildFilaProducto(productos[i], categoriaActiva),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilaProducto(Producto producto, Categoria categoria) {
    final formato = NumberFormat('#,##0', 'es_CO');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textoPrimario,
                  ),
                ),
                if (producto.descripcion != null &&
                    producto.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    producto.descripcion!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textoSecundario,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${formato.format(producto.precio)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textoPrimario,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 18),
            color: AppTheme.textoSecundario,
            visualDensity: VisualDensity.compact,
            onPressed: () => _menuProducto(producto, categoria),
          ),
        ],
      ),
    );
  }

  void _menuCategoria(Categoria cat) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _BottomSheetAcciones(
        items: [
          _AccionItem(
            icono: Icons.edit,
            label: 'Renombrar',
            onTap: () => _dialogoCategoria(cat),
          ),
          _AccionItem(
            icono: Icons.delete,
            label: 'Eliminar',
            color: AppTheme.rojo,
            onTap: () => _confirmarEliminarCategoria(cat),
          ),
        ],
      ),
    );
  }

  void _menuProducto(Producto producto, Categoria categoria) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _BottomSheetAcciones(
        items: [
          _AccionItem(
            icono: Icons.edit,
            label: 'Editar',
            onTap: () => _dialogoProducto(producto, categoria),
          ),
          _AccionItem(
            icono: Icons.delete,
            label: 'Eliminar',
            color: AppTheme.rojo,
            onTap: () => _confirmarEliminarProducto(producto),
          ),
        ],
      ),
    );
  }

  Future<void> _dialogoCategoria(Categoria? existente) async {
    final ctrl = TextEditingController(text: existente?.nombre ?? '');
    final esEditar = existente != null;

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esEditar ? 'Renombrar categoría' : 'Nueva categoría'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre de la categoría',
            border: OutlineInputBorder(),
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
    final nombre = ctrl.text.trim();
    if (nombre.isEmpty) return;

    final admin = context.read<AdminService>();
    final auth = context.read<AuthService>();
    String? error;

    if (esEditar) {
      error = await admin.actualizarCategoria(id: existente.id, nombre: nombre);
    } else {
      error = await admin.crearCategoria(
        restauranteId: auth.restaurante!['id'] as String,
        nombre: nombre,
        orden: context.read<MenuService>().categorias.length + 1,
      );
    }

    if (!mounted) return;
    if (error != null) {
      _showError(error);
    } else {
      _showOk(esEditar ? 'Categoría actualizada' : 'Categoría creada');
    }
  }

  Future<void> _dialogoProducto(
    Producto? existente,
    Categoria categoria,
  ) async {
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final descCtrl =
        TextEditingController(text: existente?.descripcion ?? '');
    final precioCtrl = TextEditingController(
      text: existente?.precio.toStringAsFixed(0) ?? '',
    );
    final esEditar = existente != null;

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esEditar ? 'Editar producto' : 'Nuevo producto'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  prefixText: '\$ ',
                  hintText: '15000',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              const Text(
                'En categoría: ',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textoTerciario,
                ),
              ),
              Text(
                categoria.nombre,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
    final nombre = nombreCtrl.text.trim();
    final desc = descCtrl.text.trim();
    final precio = double.tryParse(precioCtrl.text.trim());

    if (nombre.isEmpty || precio == null || precio <= 0) {
      _showError('Verifica el nombre y el precio');
      return;
    }

    final admin = context.read<AdminService>();
    final auth = context.read<AuthService>();
    String? error;

    if (esEditar) {
      error = await admin.actualizarProducto(
        id: existente.id,
        nombre: nombre,
        descripcion: desc.isEmpty ? null : desc,
        precio: precio,
      );
    } else {
      final cantidad =
          context.read<MenuService>().productosDeCategoria(categoria.id).length;
      error = await admin.crearProducto(
        restauranteId: auth.restaurante!['id'] as String,
        categoriaId: categoria.id,
        nombre: nombre,
        descripcion: desc.isEmpty ? null : desc,
        precio: precio,
        orden: cantidad + 1,
      );
    }

    if (!mounted) return;
    if (error != null) {
      _showError(error);
    } else {
      _showOk(esEditar ? 'Producto actualizado' : 'Producto creado');
    }
  }

  Future<void> _confirmarEliminarCategoria(Categoria cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline,
            color: AppTheme.rojo, size: 48),
        title: Text('¿Eliminar "${cat.nombre}"?'),
        content: const Text(
          'Esta acción no se puede deshacer.\nSolo se permite si la categoría no tiene productos.',
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
    final error = await context.read<AdminService>().eliminarCategoria(cat.id);
    if (!mounted) return;
    if (error != null) {
      _showError(error);
    } else {
      if (_categoriaActivaId == cat.id) {
        setState(() => _categoriaActivaId = null);
      }
      _showOk('Categoría eliminada');
    }
  }

  Future<void> _confirmarEliminarProducto(Producto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline,
            color: AppTheme.rojo, size: 48),
        title: Text('¿Eliminar "${p.nombre}"?'),
        content: const Text(
          'Esta acción no se puede deshacer.',
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
    final error = await context.read<AdminService>().eliminarProducto(p.id);
    if (!mounted) return;
    if (error != null) {
      _showError(error);
    } else {
      _showOk('Producto eliminado');
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

class _AccionItem {
  final IconData icono;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  _AccionItem({
    required this.icono,
    required this.label,
    required this.onTap,
    this.color,
  });
}

class _BottomSheetAcciones extends StatelessWidget {
  final List<_AccionItem> items;

  const _BottomSheetAcciones({required this.items});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final color = item.color ?? AppTheme.textoPrimario;
          return ListTile(
            leading: Icon(item.icono, color: color),
            title: Text(
              item.label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.of(context).pop();
              item.onTap();
            },
          );
        }).toList(),
      ),
    );
  }
}
