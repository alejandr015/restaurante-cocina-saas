import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../config/theme.dart';

/// Pantalla full-screen para visualizar el comprobante de transferencia.
///
/// Características:
/// - Zoom suave animado (no brusco)
/// - Zoom centrado en la posición del cursor (scroll del mouse)
/// - Botones de zoom + / - / ajustar en la barra superior
/// - Pinch-zoom y pan en mobile
/// - Cursor visual indicando que se puede arrastrar
class VisorComprobanteScreen extends StatefulWidget {
  final String comprobanteUrl;
  final String numeroPedido;

  const VisorComprobanteScreen({
    super.key,
    required this.comprobanteUrl,
    required this.numeroPedido,
  });

  @override
  State<VisorComprobanteScreen> createState() => _VisorComprobanteScreenState();
}

class _VisorComprobanteScreenState extends State<VisorComprobanteScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  // Para conocer el centro del viewport en zooms con botones
  final GlobalKey _viewerKey = GlobalKey();

  static const double _minScale = 0.5;
  static const double _maxScale = 6.0;
  // Pasos suaves para zoom — antes era 1.4 (40% por click), ahora 1.2 (20%)
  static const double _zoomStepBoton = 1.2;
  // Para scroll del mouse — más suave aún (5% por evento)
  static const double _zoomStepScroll = 1.05;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_animation != null) {
          _controller.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Anima la transformación desde el valor actual hasta [target] de forma suave.
  void _animarHasta(Matrix4 target) {
    _animation = Matrix4Tween(
      begin: _controller.value,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController
      ..reset()
      ..forward();
  }

  /// Calcula la transformación necesaria para hacer zoom CENTRADO en un punto local
  /// (coordenadas relativas al InteractiveViewer).
  /// Esto preserva el punto bajo el cursor mientras se hace zoom.
  Matrix4 _calcularZoomCentrado(double factor, Offset puntoLocal) {
    final actual = _controller.value.clone();
    final escalaActual = actual.getMaxScaleOnAxis();
    final escalaNueva = (escalaActual * factor).clamp(_minScale, _maxScale);
    final factorReal = escalaNueva / escalaActual;

    if (factorReal == 1.0) return actual;

    // Trasladar al punto, escalar, y trasladar de vuelta
    final resultado = Matrix4.identity()
      ..translate(puntoLocal.dx, puntoLocal.dy)
      ..scale(factorReal)
      ..translate(-puntoLocal.dx, -puntoLocal.dy)
      ..multiply(actual);

    return resultado;
  }

  /// Centro del viewport (para zoom con botones)
  Offset _centroViewport() {
    final size = (_viewerKey.currentContext?.findRenderObject() as RenderBox?)
        ?.size;
    if (size == null) {
      return Offset.zero;
    }
    return Offset(size.width / 2, size.height / 2);
  }

  void _zoomIn() {
    _animarHasta(_calcularZoomCentrado(_zoomStepBoton, _centroViewport()));
  }

  void _zoomOut() {
    _animarHasta(_calcularZoomCentrado(1 / _zoomStepBoton, _centroViewport()));
  }

  void _resetZoom() {
    _animarHasta(Matrix4.identity());
  }

  /// Zoom con scroll del mouse — centrado en posición del cursor
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Convertir posición global del cursor a local del InteractiveViewer
      final renderBox =
          _viewerKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final puntoLocal = renderBox.globalToLocal(event.position);
      final factor = event.scrollDelta.dy < 0
          ? _zoomStepScroll
          : 1 / _zoomStepScroll;

      // Para scroll, animación más corta para que se sienta responsivo
      _animation = Matrix4Tween(
        begin: _controller.value,
        end: _calcularZoomCentrado(factor, puntoLocal),
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ),
      );
      _animationController
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Comprobante #${widget.numeroPedido}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Alejar',
            icon: const Icon(Icons.zoom_out),
            onPressed: _zoomOut,
          ),
          IconButton(
            tooltip: 'Ajustar a pantalla',
            icon: const Icon(Icons.fit_screen),
            onPressed: _resetZoom,
          ),
          IconButton(
            tooltip: 'Acercar',
            icon: const Icon(Icons.zoom_in),
            onPressed: _zoomIn,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Listener(
          onPointerSignal: _handlePointerSignal,
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: InteractiveViewer(
              key: _viewerKey,
              transformationController: _controller,
              minScale: _minScale,
              maxScale: _maxScale,
              boundaryMargin: const EdgeInsets.all(80),
              clipBehavior: Clip.none,
              child: SizedBox.expand(
                child: Center(
                  child: Image.network(
                    widget.comprobanteUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Cargando comprobante...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.broken_image_outlined,
                              size: 64,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No se pudo cargar el comprobante',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              widget.comprobanteUrl,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        color: Colors.black,
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Verifica el monto, la cuenta y la fecha',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Verificado'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.verde,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
