import '../domain/celda.dart';

/// Sentinel para distinguir "no pasar este parámetro" de "pasarlo como
/// null" en [CeldaListState.copyWith] — así se puede limpiar un filtro.
const Object _unset = Object();

/// Lo que se conoce del ticket ABIERTO de una celda ocupada, sin cargar el
/// ticket completo: solo lo que ya viene en el mismo GET que arma
/// [CeldaListState.ticketInfoPorCeldaId].
typedef TicketInfo = ({String placa, TipoVehiculo tipo});

typedef _ResumenZona = ({int libres, int ocupadas, int mantenimiento, int total});

const _resumenZonaVacio = (libres: 0, ocupadas: 0, mantenimiento: 0, total: 0);

/// Todo lo que `CeldaListState` deriva de `celdas` + filtros, calculado UNA
/// SOLA VEZ al construir el estado (no en cada acceso a un getter, como
/// antes). `celdas_screen.dart` llama varios de estos varias veces por zona
/// en un solo build; con esto cada llamada es una lectura O(1) sobre lo ya
/// calculado, en vez de recorrer `celdas` de nuevo cada vez.
class _Derivados {
  const _Derivados({
    required this.totalLibres,
    required this.totalOcupadas,
    required this.totalMantenimiento,
    required this.zonas,
    required this.celdasFiltradas,
    required this.celdasFiltradasPorZona,
    required this.resumenPorZona,
  });

  final int totalLibres;
  final int totalOcupadas;
  final int totalMantenimiento;
  final List<String> zonas;
  final List<Celda> celdasFiltradas;
  final Map<String, List<Celda>> celdasFiltradasPorZona;
  final Map<String, _ResumenZona> resumenPorZona;

  static _Derivados compute({
    required List<Celda> celdas,
    required String? zonaFiltro,
    required EstadoCelda? estadoFiltro,
    required TipoVehiculo? tipoFiltro,
    required String? busquedaFiltro,
    required Map<String, TicketInfo> ticketInfoPorCeldaId,
  }) {
    bool matchBusqueda(Celda c) {
      final termino = busquedaFiltro?.trim().toLowerCase();
      if (termino == null || termino.isEmpty) return true;
      if (c.codigo.toLowerCase().contains(termino)) return true;
      final placa = ticketInfoPorCeldaId[c.id]?.placa;
      return placa != null && placa.toLowerCase().contains(termino);
    }

    var totalLibres = 0;
    var totalOcupadas = 0;
    var totalMantenimiento = 0;
    final resumenPorZona = <String, _ResumenZona>{};
    final celdasFiltradas = <Celda>[];
    final filtradasPorZona = <String, List<Celda>>{};

    // Un solo recorrido de `celdas` (no uno por cada conteo/filtro como
    // antes): totales globales, resumen por zona y filtrado salen de la
    // misma pasada.
    for (final c in celdas) {
      switch (c.estado) {
        case EstadoCelda.libre:
          totalLibres++;
        case EstadoCelda.ocupada:
          totalOcupadas++;
        case EstadoCelda.mantenimiento:
          totalMantenimiento++;
      }

      final actual = resumenPorZona[c.zona] ?? _resumenZonaVacio;
      resumenPorZona[c.zona] = (
        libres: actual.libres + (c.estado == EstadoCelda.libre ? 1 : 0),
        ocupadas: actual.ocupadas + (c.estado == EstadoCelda.ocupada ? 1 : 0),
        mantenimiento: actual.mantenimiento + (c.estado == EstadoCelda.mantenimiento ? 1 : 0),
        total: actual.total + 1,
      );

      final coincideFiltros =
          (zonaFiltro == null || c.zona == zonaFiltro) &&
          (estadoFiltro == null || c.estado == estadoFiltro) &&
          (tipoFiltro == null || c.tipoPermitido == tipoFiltro) &&
          matchBusqueda(c);
      if (coincideFiltros) {
        celdasFiltradas.add(c);
        (filtradasPorZona[c.zona] ??= []).add(c);
      }
    }

    final zonas = resumenPorZona.keys.toList()..sort();
    final celdasFiltradasPorZona = <String, List<Celda>>{
      for (final z in zonas)
        if (filtradasPorZona.containsKey(z)) z: filtradasPorZona[z]!,
    };

    return _Derivados(
      totalLibres: totalLibres,
      totalOcupadas: totalOcupadas,
      totalMantenimiento: totalMantenimiento,
      zonas: zonas,
      celdasFiltradas: celdasFiltradas,
      celdasFiltradasPorZona: celdasFiltradasPorZona,
      resumenPorZona: resumenPorZona,
    );
  }
}

class CeldaListState {
  CeldaListState({
    this.celdas = const [],
    this.isLoading = false,
    this.errorMessage,
    this.zonaFiltro,
    this.estadoFiltro,
    this.tipoFiltro,
    this.busquedaFiltro,
    this.ticketInfoPorCeldaId = const {},
  }) : _derivados = _Derivados.compute(
         celdas: celdas,
         zonaFiltro: zonaFiltro,
         estadoFiltro: estadoFiltro,
         tipoFiltro: tipoFiltro,
         busquedaFiltro: busquedaFiltro,
         ticketInfoPorCeldaId: ticketInfoPorCeldaId,
       );

  /// Lista COMPLETA de celdas, sin filtrar.
  final List<Celda> celdas;
  final bool isLoading;
  final String? errorMessage;
  final String? zonaFiltro;
  final EstadoCelda? estadoFiltro;
  final TipoVehiculo? tipoFiltro;

  /// Texto de "Buscar placa o celda". Compara contra `codigo` y, si está
  /// disponible, contra la placa del ticket abierto de esa celda (ver
  /// [ticketInfoPorCeldaId]).
  final String? busquedaFiltro;

  /// Placa y tipo real del vehículo del ticket ABIERTO de cada celda
  /// ocupada, id de celda → info. `GET /celdas` no trae esta información
  /// (ver nota en el CLAUDE.md de este proyecto); se arma en
  /// [CeldaListNotifier.refrescar] con un único GET adicional a
  /// `/tickets?estado=abierto`, no uno por celda. Una celda sin entrada acá
  /// simplemente no matchea por placa en la búsqueda y su tarjeta cae de
  /// vuelta a `celda.tipoPermitido` para el ícono — el código de celda sigue
  /// funcionando siempre en la búsqueda.
  final Map<String, TicketInfo> ticketInfoPorCeldaId;

  final _Derivados _derivados;

  CeldaListState copyWith({
    List<Celda>? celdas,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Object? zonaFiltro = _unset,
    Object? estadoFiltro = _unset,
    Object? tipoFiltro = _unset,
    Object? busquedaFiltro = _unset,
    Map<String, TicketInfo>? ticketInfoPorCeldaId,
  }) => CeldaListState(
    celdas: celdas ?? this.celdas,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    zonaFiltro: identical(zonaFiltro, _unset) ? this.zonaFiltro : zonaFiltro as String?,
    estadoFiltro: identical(estadoFiltro, _unset) ? this.estadoFiltro : estadoFiltro as EstadoCelda?,
    tipoFiltro: identical(tipoFiltro, _unset) ? this.tipoFiltro : tipoFiltro as TipoVehiculo?,
    busquedaFiltro: identical(busquedaFiltro, _unset) ? this.busquedaFiltro : busquedaFiltro as String?,
    ticketInfoPorCeldaId: ticketInfoPorCeldaId ?? this.ticketInfoPorCeldaId,
  );

  int get totalCeldas => celdas.length;

  /// Sobre la lista COMPLETA: el contador total siempre refleja la
  /// disponibilidad real, no la vista filtrada.
  int get totalLibres => _derivados.totalLibres;

  int get totalOcupadas => _derivados.totalOcupadas;

  int get totalMantenimiento => _derivados.totalMantenimiento;

  List<Celda> get celdasFiltradas => _derivados.celdasFiltradas;

  List<String> get zonas => _derivados.zonas;

  /// Conteo de una zona SIN los filtros activos: el header de zona siempre
  /// muestra la disponibilidad real de esa zona, igual que el total.
  int librresEnZona(String zona) => _derivados.resumenPorZona[zona]?.libres ?? 0;

  int ocupadasEnZona(String zona) => _derivados.resumenPorZona[zona]?.ocupadas ?? 0;

  int mantenimientoEnZona(String zona) => _derivados.resumenPorZona[zona]?.mantenimiento ?? 0;

  int totalEnZona(String zona) => _derivados.resumenPorZona[zona]?.total ?? 0;

  /// Celdas filtradas, agrupadas por zona en orden alfabético. Una zona sin
  /// celdas que coincidan con el filtro no aparece en el mapa.
  Map<String, List<Celda>> get celdasFiltradasPorZona => _derivados.celdasFiltradasPorZona;

  /// Todas las celdas LIBRE cuyo `tipoPermitido` coincide con [tipo], en el
  /// mismo orden en que aparecen en la cuadrícula (zona, luego código).
  /// Vacía si no hay ninguna disponible. Ignora los filtros activos de la
  /// pantalla de celdas a propósito: lo usa el flujo rápido de "Registrar
  /// entrada" del dashboard, que no depende de qué filtro haya quedado
  /// puesto en la cuadrícula.
  ///
  /// Una celda con `estado: LIBRE` puede seguir rechazando la entrada del
  /// backend (reservada por una mensualidad vigente de otro vehículo,
  /// ocupada un instante antes por una carrera con otro operador, etc.) —
  /// `GET /celdas` no trae esa información, así que no se puede filtrar acá.
  /// Por eso esto devuelve la lista completa de candidatas en vez de solo la
  /// primera: quien llama intenta con la primera y, si el backend la
  /// rechaza por un motivo específico de esa celda, sigue con la próxima.
  List<Celda> celdasLibresDeTipo(TipoVehiculo tipo) {
    final candidatas = celdas.where((c) => c.estado == EstadoCelda.libre && c.tipoPermitido == tipo).toList()
      ..sort((a, b) {
        final porZona = a.zona.compareTo(b.zona);
        return porZona != 0 ? porZona : a.codigo.compareTo(b.codigo);
      });
    return candidatas;
  }
}
