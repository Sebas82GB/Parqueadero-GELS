import '../../../core/domain/tipo_vehiculo.dart';
import 'mensualidad.dart';

/// Página de resultados de [MensualidadRepository.listar]. El listado de
/// mensualidades crece sin límite (a diferencia de tarifas), así que la
/// paginación se expone hasta presentación, mismo patrón que
/// `TicketPageResult`.
class MensualidadPageResult {
  const MensualidadPageResult({
    required this.data,
    required this.page,
    required this.perPage,
    required this.total,
  });

  final List<Mensualidad> data;
  final int page;
  final int perPage;
  final int total;

  bool get hayMas => page * perPage < total;
}

/// Sin dependencias de Flutter ni de dio.
abstract interface class MensualidadRepository {
  /// `GET /mensualidades` (ADMIN only). No envía `diasPorVencer`: confía en
  /// el default del backend (7 días), documentado en
  /// `Mensualidad.diasPorVencerDefault`.
  Future<MensualidadPageResult> listar({
    EstadoPagoMensualidad? estadoPago,
    String? placa,
    VigenciaMensualidad? vigencia,
    int page = 1,
    int perPage = 20,
  });

  /// `POST /mensualidades` (ADMIN only). Crea o reutiliza el vehículo por
  /// `placa`: si ya existe, el backend ignora `tipoVehiculo` y los datos de
  /// propietario del body. Lanza [ApiException] con code
  /// `CELDA_NO_ENCONTRADA` (404) o `MENSUALIDAD_SOLAPADA` (409).
  Future<Mensualidad> crear({
    required String placa,
    required TipoVehiculo tipoVehiculo,
    String? propietarioNombre,
    String? propietarioTelefono,
    String? celdaId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required int valorMensualidad,
  });

  /// `POST /mensualidades/:id/cancelar` sin body (ADMIN only). Lanza
  /// [ApiException] con code `MENSUALIDAD_YA_CANCELADA` (409).
  Future<Mensualidad> cancelar(String id);
}
