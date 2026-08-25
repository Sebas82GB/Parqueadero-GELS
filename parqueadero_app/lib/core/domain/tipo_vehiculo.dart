enum TipoVehiculo {
  carro,
  moto,
  bicicleta,
  otro;

  static TipoVehiculo fromBackend(String value) => switch (value) {
    'CARRO' => TipoVehiculo.carro,
    'MOTO' => TipoVehiculo.moto,
    'BICICLETA' => TipoVehiculo.bicicleta,
    'OTRO' => TipoVehiculo.otro,
    _ => throw FormatException('tipo de vehículo desconocido recibido del backend: $value'),
  };

  String toBackend() => switch (this) {
    TipoVehiculo.carro => 'CARRO',
    TipoVehiculo.moto => 'MOTO',
    TipoVehiculo.bicicleta => 'BICICLETA',
    TipoVehiculo.otro => 'OTRO',
  };
}
