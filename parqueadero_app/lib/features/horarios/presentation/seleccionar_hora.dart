import 'package:flutter/material.dart';

/// Firma inyectable de la selección de hora: en producción abre el picker
/// nativo de Flutter; en widget tests se overridea para devolver una
/// [TimeOfDay] fija sin abrir el diálogo real (no hay precedente en este
/// proyecto de testear el árbol interno de `TimePickerDialog`, y hacerlo
/// sería frágil entre versiones del SDK).
///
/// Compartida entre `NuevoHorarioScreen` y el diálogo de edición del
/// horario vigente en `HorariosScreen`: ambos necesitan el mismo picker en
/// modo input/24h, no dos implementaciones que puedan desalinearse.
typedef SeleccionarHora = Future<TimeOfDay?> Function(BuildContext context, TimeOfDay? inicial, String helpText);

Future<TimeOfDay?> seleccionarHoraPorDefecto(BuildContext context, TimeOfDay? inicial, String helpText) {
  return showTimePicker(
    context: context,
    initialTime: inicial ?? TimeOfDay.now(),
    // Campos de texto para hora/minuto en vez del dial: más rápido y preciso
    // a una mano bajo sol directo (contexto de uso documentado en la skill
    // de diseño).
    initialEntryMode: TimePickerEntryMode.input,
    helpText: helpText,
    // Fuerza formato 24h sin depender de la configuración del dispositivo:
    // el valor mostrado y el que se envía al backend deben ser el mismo
    // "HH:mm", sin ambigüedad de AM/PM.
    builder: (context, child) =>
        MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
  );
}

String formatHora(TimeOfDay hora) =>
    '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
