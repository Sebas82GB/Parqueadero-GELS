import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/elapsed_time.dart';
import '../../../../core/utils/money.dart';
import '../../domain/arqueo_turno.dart';
import '../../domain/turno.dart';

/// Los nueve indicadores derivados del arqueo de un turno, todos calculados
/// a partir de campos que `ArqueoTurno` ya trae (nada nuevo del backend).
/// Puro cálculo, sin Flutter, para poder testearse sin `pumpWidget`. Toda
/// división está protegida: un denominador en 0 o `null` produce `null` en
/// el campo correspondiente (nunca NaN/Infinity), y [TurnoKpisView] lo
/// muestra como "—".
class TurnoKpis {
  const TurnoKpis({
    required this.duracion,
    required this.recaudoPorHora,
    required this.ticketsPorHora,
    required this.ticketPromedio,
    required this.porcentajeEfectivo,
    required this.porcentajeTarjeta,
    required this.porcentajeTransferencia,
    required this.descuadrePorcentaje,
    required this.tiempoEsperandoArqueo,
    required this.efectivoEnCaja,
  });

  /// [ahora] es un parámetro explícito (no `DateTime.now()` interno) para
  /// que los tests puedan fijarlo, mismo criterio que `Mensualidad.vigencia`.
  factory TurnoKpis.calcular(ArqueoTurno arqueo, DateTime ahora) {
    final finDuracion = arqueo.cierre ?? ahora;
    final duracion = finDuracion.difference(arqueo.apertura);
    final horas = duracion.inSeconds / 3600;

    final totalesPorMetodo = arqueo.totalesPorMetodo;

    return TurnoKpis(
      duracion: duracion,
      recaudoPorHora: horas > 0 ? (arqueo.totalRecaudado / horas).round() : null,
      ticketsPorHora: horas > 0 ? arqueo.ticketsCerrados / horas : null,
      ticketPromedio: arqueo.ticketsCerrados > 0
          ? (arqueo.totalRecaudado / arqueo.ticketsCerrados).round()
          : null,
      porcentajeEfectivo: arqueo.totalRecaudado > 0
          ? totalesPorMetodo.efectivo / arqueo.totalRecaudado * 100
          : null,
      porcentajeTarjeta: arqueo.totalRecaudado > 0
          ? totalesPorMetodo.tarjeta / arqueo.totalRecaudado * 100
          : null,
      porcentajeTransferencia: arqueo.totalRecaudado > 0
          ? totalesPorMetodo.transferencia / arqueo.totalRecaudado * 100
          : null,
      descuadrePorcentaje: (arqueo.diferencia != null && arqueo.efectivoEsperado > 0)
          ? arqueo.diferencia! / arqueo.efectivoEsperado * 100
          : null,
      tiempoEsperandoArqueo:
          (arqueo.estado == EstadoTurno.cerradoPendienteArqueo && arqueo.cierre != null)
          ? ahora.difference(arqueo.cierre!)
          : null,
      efectivoEnCaja: arqueo.efectivoEsperado - arqueo.baseInicial,
    );
  }

  final Duration duracion;

  /// Pesos por hora. `null` si el turno lleva 0 segundos abierto.
  final int? recaudoPorHora;

  /// `null` si el turno lleva 0 segundos abierto.
  final double? ticketsPorHora;

  /// Pesos. `null` si no hay tickets cerrados. Aproximado: el denominador
  /// incluye salidas gratis por mensualidad y el numerador incluye pagos de
  /// mensualidades, así que no es un promedio por ticket cobrado exacto.
  final int? ticketPromedio;

  /// `null` si no hay recaudo todavía.
  final double? porcentajeEfectivo;
  final double? porcentajeTarjeta;
  final double? porcentajeTransferencia;

  /// `null` si [ArqueoTurno.diferencia] es `null` (arqueo aún no contado) o
  /// si `efectivoEsperado` es 0.
  final double? descuadrePorcentaje;

  /// Solo distinto de `null` mientras el turno está
  /// [EstadoTurno.cerradoPendienteArqueo].
  final Duration? tiempoEsperandoArqueo;

  /// Lo recaudado en efectivo durante el turno. Siempre calculable (resta
  /// de dos enteros, sin división).
  final int efectivoEnCaja;
}

const _guion = '—';

String _formatPorcentaje(double? valor, {bool signo = false}) {
  if (valor == null) return _guion;
  final texto = valor.toStringAsFixed(1);
  if (signo && valor >= 0) return '+$texto%';
  return '$texto%';
}

/// Bloque de indicadores derivados del arqueo, mostrado por encima de
/// `ArqueoSummaryView` en `TurnoDetailScreen`. Tarjetas pequeñas en `Wrap`
/// para que quepan en móvil sin desbordar.
class TurnoKpisView extends StatelessWidget {
  const TurnoKpisView({super.key, required this.arqueo, required this.ahora});

  final ArqueoTurno arqueo;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final kpis = TurnoKpis.calcular(arqueo, ahora);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Indicadores del turno', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _KpiTile(label: 'Duración', child: Text(formatElapsed(kpis.duracion))),
                _KpiTile(
                  label: 'Recaudo por hora',
                  child: Text(kpis.recaudoPorHora == null ? _guion : '${formatMoney(kpis.recaudoPorHora!)}/h'),
                ),
                _KpiTile(
                  label: 'Tickets por hora',
                  child: Text(kpis.ticketsPorHora == null ? _guion : kpis.ticketsPorHora!.toStringAsFixed(1)),
                ),
                _KpiTile(
                  label: 'Ticket promedio (aprox.)',
                  child: Text(kpis.ticketPromedio == null ? _guion : formatMoney(kpis.ticketPromedio!)),
                ),
                _KpiTile(
                  label: '% en efectivo',
                  child: Text(_formatPorcentaje(kpis.porcentajeEfectivo)),
                ),
                _KpiTile(
                  label: 'Composición del recaudo',
                  child: kpis.porcentajeEfectivo == null
                      ? const Text(_guion)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Efectivo ${_formatPorcentaje(kpis.porcentajeEfectivo)}'),
                            Text('Tarjeta ${_formatPorcentaje(kpis.porcentajeTarjeta)}'),
                            Text('Transferencia ${_formatPorcentaje(kpis.porcentajeTransferencia)}'),
                          ],
                        ),
                ),
                _KpiTile(
                  label: 'Descuadre / efectivo esperado',
                  child: Text(_formatPorcentaje(kpis.descuadrePorcentaje, signo: true)),
                ),
                _KpiTile(
                  label: 'Esperando arqueo',
                  child: Text(
                    kpis.tiempoEsperandoArqueo == null ? _guion : formatElapsed(kpis.tiempoEsperandoArqueo!),
                  ),
                ),
                _KpiTile(label: 'Efectivo en caja', child: Text(formatMoney(kpis.efectivoEnCaja))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.asfaltoMedio,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.asfaltoClaro, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
            ),
            const SizedBox(height: AppSpacing.xs),
            DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.titleMedium,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
