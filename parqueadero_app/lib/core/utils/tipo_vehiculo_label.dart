import 'package:flutter/material.dart';

import '../domain/tipo_vehiculo.dart';

String tipoVehiculoLabel(TipoVehiculo tipo) => switch (tipo) {
  TipoVehiculo.carro => 'Carro',
  TipoVehiculo.moto => 'Moto',
  TipoVehiculo.bicicleta => 'Bicicleta',
  TipoVehiculo.otro => 'Otro',
};

IconData tipoVehiculoIcon(TipoVehiculo tipo) => switch (tipo) {
  TipoVehiculo.carro => Icons.directions_car,
  TipoVehiculo.moto => Icons.two_wheeler,
  TipoVehiculo.bicicleta => Icons.pedal_bike,
  TipoVehiculo.otro => Icons.directions_car,
};
