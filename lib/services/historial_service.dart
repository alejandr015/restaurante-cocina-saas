import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pedido.dart';

/// Rangos de fecha predefinidos
enum RangoFecha {
  hoy,
  semana,
  mes,
  personalizado;

  String get label {
    switch (this) {
      case RangoFecha.hoy:
        return 'Hoy';
      case RangoFecha.semana:
        return 'Esta semana';
      case RangoFecha.mes:
        return 'Este mes';
      case RangoFecha.personalizado:
        return 'Personalizado';
    }
  }
}

/// Filtro de estado de pedidos
enum FiltroEstado {
  todos,
  cerrados,
  cancelados,
  activos;

  String get label {
    switch (this) {
      case FiltroEstado.todos:
        return 'Todos';
      case FiltroEstado.cerrados:
        return 'Cerrados';
      case FiltroEstado.cancelados:
        return 'Cancelados';
      case FiltroEstado.activos:
        return 'Activos';
    }
  }

  /// Estados de la BD que corresponden a este filtro
  List<String>? get estadosBD {
    switch (this) {
      case FiltroEstado.todos:
        return null; // sin filtro
      case FiltroEstado.cerrados:
        return ['cerrado'];
      case FiltroEstado.cancelados:
        return ['cancelado'];
      case FiltroEstado.activos:
        return ['nuevo', 'preparacion', 'listo', 'entregado'];
    }
  }
}

/// Servicio para consultar historial de pedidos con filtros
class HistorialService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Pedido> _pedidos = [];
  bool _cargando = false;
  String? _error;

  RangoFecha _rangoActual = RangoFecha.hoy;
  FiltroEstado _filtroEstado = FiltroEstado.todos;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  List<Pedido> get pedidos => _pedidos;
  bool get cargando => _cargando;
  String? get error => _error;
  RangoFecha get rangoActual => _rangoActual;
  FiltroEstado get filtroEstado => _filtroEstado;
  DateTime? get fechaDesde => _fechaDesde;
  DateTime? get fechaHasta => _fechaHasta;

  // ---- Métricas calculadas ----

  /// Total facturado de los pedidos cerrados del rango actual
  double get totalVentas {
    return _pedidos
        .where((p) => p.estado == EstadoPedido.cerrado)
        .fold(0.0, (sum, p) => sum + (p.total ?? 0));
  }

  int get cantidadVentasCerradas =>
      _pedidos.where((p) => p.estado == EstadoPedido.cerrado).length;

  int get cantidadTotal => _pedidos.length;

  // ---- Cambio de filtros ----

  Future<void> setRango(RangoFecha rango,
      {DateTime? desde, DateTime? hasta}) async {
    _rangoActual = rango;
    final ahora = DateTime.now();
    final hoyInicio = DateTime(ahora.year, ahora.month, ahora.day);

    switch (rango) {
      case RangoFecha.hoy:
        _fechaDesde = hoyInicio;
        _fechaHasta = hoyInicio.add(const Duration(days: 1));
        break;
      case RangoFecha.semana:
        // Lunes de esta semana (weekday: 1=lunes, 7=domingo)
        final diasDesdeLunes = ahora.weekday - 1;
        _fechaDesde = hoyInicio.subtract(Duration(days: diasDesdeLunes));
        _fechaHasta = hoyInicio.add(const Duration(days: 1));
        break;
      case RangoFecha.mes:
        _fechaDesde = DateTime(ahora.year, ahora.month, 1);
        _fechaHasta = hoyInicio.add(const Duration(days: 1));
        break;
      case RangoFecha.personalizado:
        if (desde != null) _fechaDesde = desde;
        if (hasta != null) {
          _fechaHasta = DateTime(hasta.year, hasta.month, hasta.day)
              .add(const Duration(days: 1));
        }
        break;
    }
    await cargar();
  }

  Future<void> setFiltroEstado(FiltroEstado filtro) async {
    _filtroEstado = filtro;
    await cargar();
  }

  // ---- Carga de datos ----

  Future<void> cargar() async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      // Si no hay rango establecido, usar 'hoy' como default
      if (_fechaDesde == null || _fechaHasta == null) {
        await setRango(RangoFecha.hoy);
        return;
      }

      var query = _supabase
          .from('pedidos')
          .select()
          .gte('created_at', _fechaDesde!.toIso8601String())
          .lt('created_at', _fechaHasta!.toIso8601String());

      // Aplicar filtro de estado si corresponde
      final estados = _filtroEstado.estadosBD;
      final response = estados == null
          ? await query.order('created_at', ascending: false)
          : await query
              .inFilter('estado', estados)
              .order('created_at', ascending: false);

      _pedidos = (response as List)
          .map((j) => Pedido.fromJson(j as Map<String, dynamic>))
          .toList();

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar pedidos: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  void limpiar() {
    _pedidos = [];
    _error = null;
    notifyListeners();
  }
}
