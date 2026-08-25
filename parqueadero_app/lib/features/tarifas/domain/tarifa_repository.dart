import 'tarifa.dart';

/// Sin dependencias de Flutter ni de dio.
abstract interface class TarifaRepository {
  /// Trae TODAS las tarifas, paginando internamente `GET /tarifas` hasta
  /// agotar `meta.total`. La agrupación por tipo y la vigente/histórico se
  /// calculan en presentación sobre esta lista: no existe un endpoint de
  /// agregación y un parqueadero tiene a lo sumo unas decenas de tarifas.
  Future<List<Tarifa>> listarTodas();

  /// `POST /tarifas`. Cierra automáticamente (del lado del servidor) la
  /// vigencia anterior del mismo `tipoVehiculo`. Lanza [ApiException] si la
  /// validación falla.
  Future<Tarifa> crear({
    required TipoVehiculo tipoVehiculo,
    required int valorMinuto,
    required int valorPlena,
    required int valorNocturna,
    required int valorMes,
  });

  /// `POST /tarifas/:id/cerrar` sin body. Cierra la vigencia sin
  /// reemplazarla. Lanza [ApiException] con code `TARIFA_NO_ENCONTRADA` (404)
  /// o `TARIFA_YA_CERRADA` (409).
  Future<Tarifa> cerrar(String id);

  /// `POST /tarifas/simular`. Solo lectura: no persiste nada, requiere rol
  /// ADMIN (mismo que crear/cerrar). Devuelve el `valorTotal` que resultaría
  /// de esa tarifa hipotética para la duración dada, calculado por el
  /// backend con las reglas reales de cobro (bloques de 6h, nocturna, corte
  /// 6 AM) — la app nunca las reimplementa. Devuelve null si `tipoVehiculo`
  /// es OTRO: ese tipo no tiene cálculo automático, el valor lo digita el
  /// operador al registrar la salida.
  Future<int?> simular({
    required TipoVehiculo tipoVehiculo,
    required int valorMinuto,
    required int valorPlena,
    required int valorNocturna,
    required int duracionMinutos,
  });
}
