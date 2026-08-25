import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/bogota_time.dart';
import '../../../../core/utils/tipo_vehiculo_label.dart';
import '../../domain/recibo.dart';
import 'desglose_view.dart';
import 'metodo_pago_label.dart';

/// 80mm ≈ 3.15in a 96dpi ≈ 302px lógicos: ancho de una tirilla térmica
/// estándar. `window.print()` imprime lo que está en pantalla, así que este
/// widget se diseña ya angosto y centrado, no una pantalla completa.
const kReciboAnchoMm80 = 302.0;

/// Formato de tirilla, deliberadamente en blanco y negro: una impresora
/// térmica no tiene color, así que acá no se usa ni la paleta de marca ni la
/// de estados (`AppColors`/`StatusStyle`) — lo único que importa es que se
/// vea igual en pantalla que en el papel.
class ReciboView extends StatelessWidget {
  const ReciboView({super.key, required this.recibo});

  final Recibo recibo;

  static const _pieStyle = TextStyle(fontSize: 10);

  @override
  Widget build(BuildContext context) {
    final establecimiento = recibo.establecimiento;
    return Container(
      width: kReciboAnchoMm80,
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'monospace', color: Colors.black, fontSize: 12, height: 1.4),
        textAlign: TextAlign.center,
        child: Theme(
          // DesgloseView toma sus estilos de Theme.of(context).textTheme; se
          // fuerza acá a blanco y negro para que el desglose no traiga los
          // colores de marca del resto de la app.
          data: Theme.of(context).copyWith(
            textTheme: Typography.blackMountainView.apply(fontFamily: 'monospace'),
            dividerTheme: const DividerThemeData(color: Colors.black),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                establecimiento.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text('NIT ${establecimiento.nit}'),
              Text(establecimiento.direccion),
              Text('${establecimiento.ciudad} · ${establecimiento.telefono}'),
              Text(establecimiento.regimenTributario),
              Text(establecimiento.numeroResolucion),
              const Divider(color: Colors.black, height: 20),
              Align(alignment: Alignment.centerLeft, child: Text('Recibo No. ${recibo.consecutivo}')),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Fecha: ${formatBogota(recibo.fechaEmision)}'),
              ),
              if (recibo.operador != null)
                Align(alignment: Alignment.centerLeft, child: Text('Operador: ${recibo.operador}')),
              const SizedBox(height: AppSpacing.sm),
              Align(alignment: Alignment.centerLeft, child: Text('Placa: ${recibo.placa}')),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Tipo: ${tipoVehiculoLabel(recibo.tipoVehiculo)}'),
              ),
              Align(alignment: Alignment.centerLeft, child: Text('Celda: ${recibo.celda}')),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Entrada: ${formatBogota(recibo.horaEntrada)}'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Salida: ${formatBogota(recibo.horaSalida)}'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Tiempo total: ${recibo.tiempoTotal}'),
              ),
              if (recibo.metodoPago != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Método de pago: ${metodoPagoLabel(recibo.metodoPago!)}'),
                ),
              const Divider(color: Colors.black, height: 20),
              DesgloseView(desglose: recibo.desglose, valorTotal: recibo.total),
              const Divider(color: Colors.black, height: 20),
              Text(establecimiento.textoResponsabilidad, style: _pieStyle),
              const SizedBox(height: AppSpacing.xs),
              Text(establecimiento.textoSeguro, style: _pieStyle),
              const SizedBox(height: AppSpacing.xs),
              Text(establecimiento.textoHorario, style: _pieStyle),
              const SizedBox(height: AppSpacing.xs),
              Text(establecimiento.textoReclamos, style: _pieStyle),
            ],
          ),
        ),
      ),
    );
  }
}
