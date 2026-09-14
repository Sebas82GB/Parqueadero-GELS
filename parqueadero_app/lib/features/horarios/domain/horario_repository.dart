import 'horario.dart';

/// Sin dependencias de Flutter ni de dio.
abstract interface class HorarioRepository {
  /// Trae TODOS los horarios, paginando internamente `GET /horarios` hasta
  /// agotar `meta.total`. La vigente/histórico se calcula en presentación
  /// sobre esta lista: no existe un endpoint de agregación y un parqueadero
  /// cambia de horario muy pocas veces.
  Future<List<Horario>> listarTodas();

  /// `POST /horarios`. Cierra automáticamente (del lado del servidor, en la
  /// misma transacción) el vigente anterior. Lanza [ApiException] si la
  /// validación falla (formato `HH:mm` o `cierre` no posterior a `apertura`).
  Future<Horario> crear({required String apertura, required String cierre});

  /// `PATCH /horarios/:id` con body parcial: solo los campos no nulos viajan
  /// en la petición. Lanza [ApiException] con code `VALIDATION_ERROR` (400,
  /// body vacío o campo desconocido), `HORARIO_NO_ENCONTRADO` (404),
  /// `HORARIO_CON_TICKETS_ASOCIADOS` (409, la vigencia ya se usó y no se
  /// puede editar) o `HORARIO_RANGO_INVALIDO` (422, el cierre resultante no
  /// es posterior a la apertura).
  Future<Horario> actualizar(String id, {String? apertura, String? cierre});

  /// `POST /horarios/:id/cerrar` sin body. Cierra la vigencia sin
  /// reemplazarla. Lanza [ApiException] con code `HORARIO_NO_ENCONTRADO`
  /// (404) o `HORARIO_YA_CERRADO` (409).
  Future<Horario> cerrar(String id);
}
