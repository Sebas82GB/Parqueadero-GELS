import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/elapsed_time.dart';

/// Texto de "tiempo transcurrido desde [horaEntrada]" que se refresca solo,
/// cada 30s, con su propio `Timer.periodic`. Aislado en su propio widget para
/// que el `setState` del tick no reconstruya la pantalla que lo contiene —
/// esta es la única parte de esas pantallas que necesita repintarse cada 30s.
class TiempoTranscurridoText extends StatefulWidget {
  const TiempoTranscurridoText({super.key, required this.horaEntrada, this.style});

  /// UTC, igual que llega del backend (ver CLAUDE.md §3, regla 6).
  final DateTime horaEntrada;
  final TextStyle? style;

  @override
  State<TiempoTranscurridoText> createState() => _TiempoTranscurridoTextState();
}

class _TiempoTranscurridoTextState extends State<TiempoTranscurridoText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transcurrido = DateTime.now().toUtc().difference(widget.horaEntrada);
    return Text(formatElapsed(transcurrido), style: widget.style);
  }
}
