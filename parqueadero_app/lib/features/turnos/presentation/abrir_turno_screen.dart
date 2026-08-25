import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/button_spinner.dart';
import 'abrir_turno_notifier.dart';

/// Se llega acá al recibir `OPERADOR_SIN_TURNO_ABIERTO` al registrar una
/// salida. Al confirmar, se vuelve (`pop`) a esa pantalla y el operador
/// reintenta el cierre manualmente — no hay auto-retry.
///
/// Escribe dinero (la base inicial de caja determina la "diferencia" del
/// cierre de turno, horas después), así que sigue el mismo patrón que
/// registrar salida y cerrar turno: diálogo "¿confirmar?" con el monto antes
/// de llamar al backend, y confirmación explícita de éxito antes de volver
/// — ninguna de las dos existía antes, y el campo venía precargado en '0',
/// lo que dejaba abrir un turno con base equivocada a un toque de distancia
/// y sin ninguna señal de que había pasado.
class AbrirTurnoScreen extends ConsumerStatefulWidget {
  const AbrirTurnoScreen({super.key});

  @override
  ConsumerState<AbrirTurnoScreen> createState() => _AbrirTurnoScreenState();
}

class _AbrirTurnoScreenState extends ConsumerState<AbrirTurnoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseInicialController = TextEditingController();

  @override
  void dispose() {
    _baseInicialController.dispose();
    super.dispose();
  }

  Future<void> _confirmarYAbrir() async {
    if (!_formKey.currentState!.validate()) return;
    final baseInicial = int.parse(_baseInicialController.text.trim());

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Abrir turno?'),
        content: Text('Se abrirá el turno con una base inicial de ${formatMoney(baseInicial)}.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final exito = await ref.read(abrirTurnoNotifierProvider.notifier).abrir(baseInicial);
    if (!exito || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Turno abierto'),
        content: Text('Base inicial: ${formatMoney(baseInicial)}.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Aceptar')),
        ],
      ),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(abrirTurnoNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Abrir turno')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _baseInicialController,
                      enabled: !state.isLoading,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Base inicial de caja'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Ingresa la base inicial';
                        final n = int.tryParse(value.trim());
                        if (n == null || n < 0) return 'Ingresa un valor válido';
                        return null;
                      },
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: state.isLoading ? null : _confirmarYAbrir,
                      child: state.isLoading ? const ButtonSpinner() : const Text('Abrir turno'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
