import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/app_spacing.dart';

/// El texto siempre es `error.message` del backend/[NetworkException]
/// verbatim; el `switch` exhaustivo sobre el sealed type [AppException] solo
/// cambia el ícono/layout entre un error de red y uno de credenciales/API,
/// nunca la redacción. Cuando el error es un [ApiException] con `details`
/// (p.ej. `400 Datos de entrada inválidos` de un validador Zod), el motivo
/// real de cada campo se agrega debajo del `message`, también verbatim.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.error});

  final AppException error;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return switch (error) {
      NetworkException() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(error.message, style: TextStyle(color: color), textAlign: TextAlign.center)),
        ],
      ),
      ApiException(:final details) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error.message, style: TextStyle(color: color), textAlign: TextAlign.center),
          if (details.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              details.map((d) => d.message).join('\n'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    };
  }
}
