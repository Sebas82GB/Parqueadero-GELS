import 'celda.dart';

/// Sin dependencias de Flutter ni de dio.
abstract interface class CeldaRepository {
  /// Trae TODAS las celdas, paginando internamente `GET /celdas` hasta
  /// agotar `meta.total`. Los filtros de zona/estado/tipo y los contadores
  /// de disponibilidad se calculan en presentación sobre esta lista: no
  /// existe un endpoint de agregación y un parqueadero tiene a lo sumo unos
  /// cientos de celdas.
  Future<List<Celda>> listarTodas();

  /// `PATCH /celdas/:id/mantenimiento`. Lanza [ApiException] con code
  /// `CELDA_OCUPADA` o `CELDA_ESTADO_INVALIDO` si la transición no es válida
  /// — la decide el backend, no este repositorio.
  Future<Celda> marcarMantenimiento(String id);

  /// `PATCH /celdas/:id/liberar`. Misma lógica de errores que
  /// [marcarMantenimiento].
  Future<Celda> volverALibre(String id);
}
