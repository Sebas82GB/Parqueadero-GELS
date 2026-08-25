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
}
