import 'package:flutter_test/flutter_test.dart';
import 'package:parqueadero_app/features/tickets/data/dtos/recibo_dto.dart';
import 'package:parqueadero_app/features/tickets/domain/desglose_item.dart';
import 'package:parqueadero_app/features/tickets/domain/pago.dart';

Map<String, dynamic> _establecimientoJson() => {
  'nombre': 'Parqueadero Ejemplo S.A.S.',
  'nit': '900.123.456-7',
  'direccion': 'Calle 100 # 15-20',
  'telefono': '(601) 555-0000',
  'ciudad': 'Bogotá D.C.',
  'regimenTributario': 'Régimen común',
  'numeroResolucion': 'Resolución DIAN 000000000000',
  'textoResponsabilidad': 'El establecimiento no se hace responsable...',
  'textoSeguro': 'Este parqueadero cuenta con póliza de seguro...',
  'textoHorario': 'Horario de atención: 6:00 a.m. a 9:00 p.m.',
  'textoReclamos': 'Reclamos dentro de las 24 horas siguientes...',
};

Map<String, dynamic> _reciboJson({String? metodoPago, String? operador}) => {
  'consecutivo': 123,
  'fechaEmision': '2026-01-01T18:00:00.000Z',
  'establecimiento': _establecimientoJson(),
  'placa': 'ABC123',
  'tipoVehiculo': 'CARRO',
  'celda': 'A-01',
  'horaEntrada': '2026-01-01T16:30:00.000Z',
  'horaSalida': '2026-01-01T18:00:00.000Z',
  'tiempoTotal': '1h 30min',
  'desglose': [
    {
      'dia': 1,
      'bloqueNumero': 1,
      'inicio': '2026-01-01T16:30:00.000Z',
      'fin': '2026-01-01T18:00:00.000Z',
      'minutos': 90,
      'tipoCobro': 'PARCIAL',
      'valor': 9000,
    },
  ],
  'total': 9000,
  'metodoPago': metodoPago,
  'operador': operador,
};

void main() {
  test('parsea el establecimiento anidado', () {
    final recibo = ReciboDto.fromJson(_reciboJson(metodoPago: 'EFECTIVO', operador: 'Ana')).toDomain();

    expect(recibo.establecimiento.nombre, 'Parqueadero Ejemplo S.A.S.');
    expect(recibo.establecimiento.nit, '900.123.456-7');
  });

  test('parsea consecutivo, fechas, placa, celda, tiempoTotal y total', () {
    final recibo = ReciboDto.fromJson(_reciboJson()).toDomain();

    expect(recibo.consecutivo, 123);
    expect(recibo.fechaEmision, DateTime.utc(2026, 1, 1, 18));
    expect(recibo.placa, 'ABC123');
    expect(recibo.celda, 'A-01');
    expect(recibo.tiempoTotal, '1h 30min');
    expect(recibo.total, 9000);
  });

  test('reutiliza desgloseFromJson: el desglose queda tipado como DesgloseBloque', () {
    final recibo = ReciboDto.fromJson(_reciboJson()).toDomain();

    expect(recibo.desglose, hasLength(1));
    expect(recibo.desglose.single, isA<DesgloseBloque>());
  });

  test('metodoPago y operador null (ticket sin pago aún vinculado): quedan null', () {
    final recibo = ReciboDto.fromJson(_reciboJson()).toDomain();

    expect(recibo.metodoPago, isNull);
    expect(recibo.operador, isNull);
  });

  test('metodoPago y operador presentes: se parsean', () {
    final recibo = ReciboDto.fromJson(_reciboJson(metodoPago: 'TARJETA', operador: 'Ana Pérez')).toDomain();

    expect(recibo.metodoPago, MetodoPago.tarjeta);
    expect(recibo.operador, 'Ana Pérez');
  });
}
