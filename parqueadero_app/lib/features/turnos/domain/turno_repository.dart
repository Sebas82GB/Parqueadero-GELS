import 'arqueo_turno.dart';
import 'turno.dart';

/// Página de resultados de [TurnoRepository.listar]. Mismo criterio que
/// `TicketPageResult`: el historial de turnos crece sin límite, así que la
/// paginación se expone hasta presentación.
class TurnoPageResult {
  const TurnoPageResult({required this.data, required this.page, required this.perPage, required this.total});

  final List<Turno> data;
  final int page;
  final int perPage;
  final int total;

  bool get hayMas => page * perPage < total;
}

/// Sin dependencias de Flutter ni de dio.
abstract interface class TurnoRepository {
  /// `POST /turnos`. El operador siempre confirma esta acción explícitamente
  /// (nunca se llama en segundo plano). Si se omite [baseInicial], el
  /// backend usa la que un ADMIN configuró para la apertura automática — el
  /// operador no tiene que digitarla. Lanza [ApiException] con code
  /// `TURNO_YA_ABIERTO` (409) si ya tiene uno abierto, o
  /// `BASE_INICIAL_NO_CONFIGURADA` (422) si se omitió y ningún ADMIN
  /// configuró una.
  Future<Turno> abrir([int? baseInicial]);

  /// `POST /turnos/:id/cierre`. Devuelve el arqueo completo del turno recién
  /// cerrado en la misma respuesta. Lanza [ApiException] con `CONFLICT` (409)
  /// si ya estaba cerrado, `FORBIDDEN` (403) si quien llama no es el dueño ni
  /// ADMIN, `NOT_FOUND` (404) si el turno no existe.
  Future<ArqueoTurno> cerrar(String turnoId, int efectivoContado);

  /// `GET /turnos/:id/arqueo`. Disponible con el turno abierto (parcial, en
  /// vivo), pendiente de arqueo o cerrado (final). Mismos codes de error que
  /// [cerrar] salvo `CONFLICT`.
  Future<ArqueoTurno> obtenerArqueo(String turnoId);

  /// `POST /turnos/:id/completar-arqueo`. Solo para un turno
  /// [EstadoTurno.cerradoPendienteArqueo] — el turno automático ya cerró la
  /// ventana horaria y nadie había contado caja. Devuelve el arqueo final, ya
  /// con `estado` en `CERRADO`. Lanza [ApiException] con `FORBIDDEN` (403) si
  /// quien llama no es ADMIN (a diferencia de [cerrar], acá no hay excepción
  /// para el operador dueño), `NOT_FOUND` (404) si el turno no existe, o
  /// `CONFLICT` (409) si no estaba pendiente de arqueo.
  Future<ArqueoTurno> completarArqueo(String turnoId, int efectivoContado);

  /// `GET /turnos` con filtros, paginado. Un OPERADOR ve solo los suyos aunque
  /// mande otro `operadorId` — el backend lo fuerza igual.
  Future<TurnoPageResult> listar({
    String? operadorId,
    EstadoTurno? estado,
    DateTime? desde,
    DateTime? hasta,
    int page = 1,
    int perPage = 20,
  });
}
