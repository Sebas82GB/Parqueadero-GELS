import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/app_spacing.dart';

/// El texto siempre es `error.message` del backend/[NetworkException]
/// verbatim; el `switch` exhaustivo sobre el sealed type [AppException] solo
/// cambia el ícono/layout entre un error de red y uno de credenciales/API,
/// nunca la redacción.
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
      ApiException() => Text(error.message, style: TextStyle(color: color), textAlign: TextAlign.center),
    };
  }
}
