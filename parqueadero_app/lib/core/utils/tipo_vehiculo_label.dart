import '../domain/tipo_vehiculo.dart';

String tipoVehiculoLabel(TipoVehiculo tipo) => switch (tipo) {
  TipoVehiculo.carro => 'Carro',
  TipoVehiculo.moto => 'Moto',
  TipoVehiculo.bicicleta => 'Bicicleta',
  TipoVehiculo.otro => 'Otro',
};
