import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/pedido.dart';

/// Tarjeta individual de pedido para el tablero kanban.
///
/// Estructura:
/// - Container exterior con borderRadius (y borde gris uniforme)
/// - Una franja de color a la izquierda (Container interno) que indica el estado
/// - Padding y contenido a la derecha
///
/// Esto evita el error "borderRadius can only be given on borders with
/// uniform colors" que ocurre al mezclar borde redondeado con un lado
/// de color distinto.
class TarjetaPedido extends StatelessWidget {
  final Pedido pedido;
  final Color colorRestaurante;
  final VoidCallback? onAccion;
  final VoidCallback? onCancelar;

  const TarjetaPedido({
    super.key,
    required this.pedido,
    required this.colorRestaurante,
    this.onAccion,
    this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final esListo = pedido.estado == EstadoPedido.listo;

    return DefaultTextStyle(
      style: const TextStyle(
        color: AppTheme.textoPrimario,
        fontSize: 13,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.superficie,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borde, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Opacity(
            opacity: esListo ? 0.85 : 1.0,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Franja de color del estado
                  Container(width: 4, color: pedido.estado.color),
                  // Contenido principal
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildContenido(esListo),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContenido(bool esListo) {
    final widgets = <Widget>[
      _buildEncabezado(),
      const SizedBox(height: 6),
      Text(
        '${pedido.clienteNombre} · ${pedido.tipo.label}',
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textoSecundario,
        ),
      ),
    ];

    if (pedido.tipo == TipoPedido.domicilio && pedido.direccion != null) {
      widgets.addAll([
        const SizedBox(height: 2),
        Text(
          pedido.clienteTelefono != null
              ? '${pedido.direccion} · Tel ${pedido.clienteTelefono}'
              : pedido.direccion!,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textoTerciario,
          ),
        ),
      ]);
    }

    widgets.add(const SizedBox(height: 8));

    if (!esListo) {
      widgets.add(Container(height: 0.5, color: AppTheme.borde));
      widgets.add(const SizedBox(height: 8));
      for (final item in pedido.items) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '${item.cantidad}× ${item.nombre}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textoPrimario,
              ),
            ),
          ),
        );
      }
      if (pedido.notas != null && pedido.notas!.isNotEmpty) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(_buildNotas());
      }
      widgets.add(const SizedBox(height: 10));
    } else {
      widgets.add(const SizedBox(height: 4));
      widgets.add(
        Text(
          pedido.tipo == TipoPedido.domicilio
              ? 'Notificado al cliente'
              : 'Listo para servir',
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textoTerciario,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));
    }

    if (onAccion != null) widgets.add(_buildBotonAccion());
    if (onCancelar != null && pedido.estado == EstadoPedido.nuevo) {
      widgets.add(_buildBotonCancelar());
    }

    return widgets;
  }

  Widget _buildEncabezado() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '#${pedido.numeroPedido}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textoPrimario,
          ),
        ),
        Text(
          _textoTiempo(),
          style: TextStyle(
            fontSize: 11,
            color: pedido.estado.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _textoTiempo() {
    switch (pedido.estado) {
      case EstadoPedido.preparacion:
        return '⏱  ${pedido.tiempoFormateado}';
      case EstadoPedido.listo:
        return '✓ listo';
      default:
        return 'hace ${pedido.tiempoFormateado}';
    }
  }

  Widget _buildNotas() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.amarilloFondo,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: AppTheme.amarilloOscuro,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              pedido.notas!,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.amarilloOscuro,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonAccion() {
    final config = _configBoton();
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onAccion,
        style: ElevatedButton.styleFrom(
          backgroundColor: config.fondo,
          foregroundColor: config.texto,
          side: config.borde,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          config.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: config.texto,
          ),
        ),
      ),
    );
  }

  _ConfigBoton _configBoton() {
    switch (pedido.estado) {
      case EstadoPedido.nuevo:
        return _ConfigBoton(
          label: 'Aceptar  →',
          fondo: colorRestaurante,
          texto: Colors.white,
          borde: null,
        );
      case EstadoPedido.preparacion:
        return _ConfigBoton(
          label: '✓  Terminado',
          fondo: AppTheme.verde,
          texto: Colors.white,
          borde: null,
        );
      case EstadoPedido.listo:
        return _ConfigBoton(
          label: 'Entregado',
          fondo: Colors.white,
          texto: AppTheme.textoPrimario,
          borde: const BorderSide(color: AppTheme.borde, width: 0.5),
        );
      default:
        return _ConfigBoton(
          label: '',
          fondo: Colors.white,
          texto: AppTheme.textoPrimario,
          borde: null,
        );
    }
  }

  Widget _buildBotonCancelar() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: onCancelar,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textoTerciario,
            padding: const EdgeInsets.symmetric(vertical: 4),
            minimumSize: Size.zero,
          ),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textoTerciario,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigBoton {
  final String label;
  final Color fondo;
  final Color texto;
  final BorderSide? borde;

  _ConfigBoton({
    required this.label,
    required this.fondo,
    required this.texto,
    required this.borde,
  });
}
