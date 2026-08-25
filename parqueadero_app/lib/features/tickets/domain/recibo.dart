import '../../../core/domain/tipo_vehiculo.dart';
import 'desglose_item.dart';
import 'pago.dart';

/// Datos fijos del negocio que el backend arma desde variables de entorno
/// (`ESTABLECIMIENTO_*`), embebidos dentro de cada [Recibo] — no hay que
/// pedirlos por separado.
class Establecimiento {
  const Establecimiento({
    required this.nombre,
    required this.nit,
    required this.direccion,
    required this.telefono,
    required this.ciudad,
    required this.regimenTributario,
    required this.numeroResolucion,
    required this.textoResponsabilidad,
    required this.textoSeguro,
    required this.textoHorario,
    required this.textoReclamos,
  });

  final String nombre;
  final String nit;
  final String direccion;
  final String telefono;
  final String ciudad;
  final String regimenTributario;
  final String numeroResolucion;
  final String textoResponsabilidad;
  final String textoSeguro;
  final String textoHorario;
  final String textoReclamos;
}

/// Recibo de salida, ya calculado por el backend (`recibo.service.js`,
/// `construirRecibo`). Viaja embebido en la respuesta de `GET /tickets/:id`
/// y `POST /tickets/:id/salida` como `Ticket.recibo`, `null` mientras el
/// ticket sigue `ABIERTO` — no existe un endpoint propio para pedirlo.
class Recibo {
  const Recibo({
    required this.consecutivo,
    required this.fechaEmision,
    required this.establecimiento,
    required this.placa,
    required this.tipoVehiculo,
    required this.celda,
    required this.horaEntrada,
    required this.horaSalida,
    required this.tiempoTotal,
    required this.desglose,
    required this.total,
    required this.metodoPago,
    required this.operador,
  });

  final int consecutivo;
  final DateTime fechaEmision;
  final Establecimiento establecimiento;
  final String placa;
  final TipoVehiculo tipoVehiculo;

  /// Código de la celda (p. ej. "A-01"), no su id.
  final String celda;
  final DateTime horaEntrada;
  final DateTime horaSalida;

  /// Ya formateado por el backend (`duracion.util.js`): "45min", "1h 30min",
  /// "1d 3h 15min". La app no recalcula duraciones para el recibo.
  final String tiempoTotal;
  final List<DesgloseItem> desglose;
  final int total;
  final MetodoPago? metodoPago;
  final String? operador;
}
