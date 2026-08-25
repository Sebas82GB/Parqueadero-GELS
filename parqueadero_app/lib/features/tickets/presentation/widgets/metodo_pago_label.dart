import '../../domain/pago.dart';

String metodoPagoLabel(MetodoPago metodo) => switch (metodo) {
  MetodoPago.efectivo => 'Efectivo',
  MetodoPago.tarjeta => 'Tarjeta',
  MetodoPago.transferencia => 'Transferencia',
};
