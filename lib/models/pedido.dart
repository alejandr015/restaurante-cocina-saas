import 'package:flutter/material.dart';

/// Estados posibles de un pedido
enum EstadoPedido {
  nuevo,
  preparacion,
  listo,
  entregado,
  cancelado,
  cerrado;

  String get label {
    switch (this) {
      case EstadoPedido.nuevo:
        return 'Nuevo';
      case EstadoPedido.preparacion:
        return 'En preparación';
      case EstadoPedido.listo:
        return 'Listo';
      case EstadoPedido.entregado:
        return 'Entregado';
      case EstadoPedido.cancelado:
        return 'Cancelado';
      case EstadoPedido.cerrado:
        return 'Cerrado';
    }
  }

  Color get color {
    switch (this) {
      case EstadoPedido.nuevo:
        return const Color(0xFFE24B4A);
      case EstadoPedido.preparacion:
        return const Color(0xFFEF9F27);
      case EstadoPedido.listo:
        return const Color(0xFF639922);
      case EstadoPedido.entregado:
        return const Color(0xFF888780);
      case EstadoPedido.cancelado:
        return const Color(0xFF5F5E5A);
      case EstadoPedido.cerrado:
        return const Color(0xFF888780);
    }
  }

  static EstadoPedido fromString(String value) {
    return EstadoPedido.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoPedido.nuevo,
    );
  }
}

/// Tipo de pedido: domicilio o local
enum TipoPedido {
  domicilio,
  local;

  String get label => this == TipoPedido.domicilio ? 'Domicilio' : 'Local';

  static TipoPedido fromString(String value) {
    return value == 'local' ? TipoPedido.local : TipoPedido.domicilio;
  }
}

/// Método de pago del pedido
enum MetodoPago {
  efectivo,
  transferencia;

  String get label {
    switch (this) {
      case MetodoPago.efectivo:
        return 'Efectivo';
      case MetodoPago.transferencia:
        return 'Transferencia';
    }
  }

  String get emoji {
    switch (this) {
      case MetodoPago.efectivo:
        return '💵';
      case MetodoPago.transferencia:
        return '💳';
    }
  }

  static MetodoPago? fromString(String? value) {
    if (value == null) return null;
    return MetodoPago.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MetodoPago.efectivo,
    );
  }
}

/// Zona del domicilio (cercano/medio/lejano)
enum ZonaDomicilio {
  cercano,
  medio,
  lejano;

  String get label {
    switch (this) {
      case ZonaDomicilio.cercano:
        return 'Cercano';
      case ZonaDomicilio.medio:
        return 'Medio';
      case ZonaDomicilio.lejano:
        return 'Lejano';
    }
  }

  static ZonaDomicilio? fromString(String? value) {
    if (value == null) return null;
    return ZonaDomicilio.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ZonaDomicilio.medio,
    );
  }
}

class ItemPedido {
  final String nombre;
  final int cantidad;
  final double precio;

  ItemPedido({
    required this.nombre,
    required this.cantidad,
    required this.precio,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> json) => ItemPedido(
    nombre: json['nombre'] as String,
    cantidad: json['cantidad'] as int,
    precio: (json['precio'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'cantidad': cantidad,
    'precio': precio,
  };

  double get subtotal => precio * cantidad;
}

class Pedido {
  final int id;
  final String numeroPedido;
  final TipoPedido tipo;
  final EstadoPedido estado;
  final String clienteNombre;
  final String? clienteTelefono;
  final String? clienteWhatsapp;
  final String? direccion;
  final String? mesa;
  final List<ItemPedido> items;
  final String? notas;
  final double? total;
  final DateTime createdAt;
  final DateTime? preparacionAt;
  final DateTime? listoAt;

  // NUEVOS CAMPOS
  final MetodoPago? metodoPago;
  final String? comprobanteUrl;
  final double? costoDomicilio;
  final ZonaDomicilio? zonaDomicilio;

  Pedido({
    required this.id,
    required this.numeroPedido,
    required this.tipo,
    required this.estado,
    required this.clienteNombre,
    this.clienteTelefono,
    this.clienteWhatsapp,
    this.direccion,
    this.mesa,
    required this.items,
    this.notas,
    this.total,
    required this.createdAt,
    this.preparacionAt,
    this.listoAt,
    this.metodoPago,
    this.comprobanteUrl,
    this.costoDomicilio,
    this.zonaDomicilio,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>;
    return Pedido(
      id: json['id'] as int,
      numeroPedido: json['numero_pedido'] as String,
      tipo: TipoPedido.fromString(json['tipo'] as String),
      estado: EstadoPedido.fromString(json['estado'] as String),
      clienteNombre: json['cliente_nombre'] as String,
      clienteTelefono: json['cliente_telefono'] as String?,
      clienteWhatsapp: json['cliente_whatsapp'] as String?,
      direccion: json['direccion'] as String?,
      mesa: json['mesa'] as String?,
      items: itemsRaw
          .map((i) => ItemPedido.fromJson(i as Map<String, dynamic>))
          .toList(),
      notas: json['notas'] as String?,
      total: json['total'] != null ? (json['total'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      preparacionAt: json['preparacion_at'] != null
          ? DateTime.parse(json['preparacion_at'] as String)
          : null,
      listoAt: json['listo_at'] != null
          ? DateTime.parse(json['listo_at'] as String)
          : null,
      // Nuevos campos (todos opcionales para no romper pedidos viejos)
      metodoPago: MetodoPago.fromString(json['metodo_pago'] as String?),
      comprobanteUrl: json['comprobante_url'] as String?,
      costoDomicilio: json['costo_domicilio'] != null
          ? (json['costo_domicilio'] as num).toDouble()
          : null,
      zonaDomicilio: ZonaDomicilio.fromString(json['zona_domicilio'] as String?),
    );
  }

  Duration get tiempoTranscurrido => DateTime.now().difference(createdAt);

  String get tiempoFormateado {
    final mins = tiempoTranscurrido.inMinutes;
    if (mins < 1) return 'recién';
    if (mins < 60) return '$mins min';
    final h = tiempoTranscurrido.inHours;
    return '${h}h ${mins % 60}min';
  }

  String get ubicacionLabel {
    if (tipo == TipoPedido.local) return 'Mesa $mesa';
    return direccion ?? 'Domicilio';
  }

  /// Indica si el pedido tiene comprobante de transferencia adjunto
  bool get tieneComprobante =>
      comprobanteUrl != null && comprobanteUrl!.isNotEmpty;

  /// Indica si requiere verificación del comprobante (transferencia con foto)
  bool get requiereVerificacion =>
      metodoPago == MetodoPago.transferencia && tieneComprobante;
}
