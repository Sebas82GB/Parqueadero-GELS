import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/tipo_vehiculo_label.dart';
import '../../../core/utils/upper_case_text_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/acceso_restringido.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/session_notifier.dart';
import '../../celdas/domain/celda.dart';
import '../../celdas/presentation/celda_list_notifier.dart';
import 'nueva_mensualidad_notifier.dart';

class NuevaMensualidadScreen extends ConsumerStatefulWidget {
  const NuevaMensualidadScreen({super.key});

  @override
  ConsumerState<NuevaMensualidadScreen> createState() => _NuevaMensualidadScreenState();
}

class _NuevaMensualidadScreenState extends ConsumerState<NuevaMensualidadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _propietarioNombreController = TextEditingController();
  final _propietarioTelefonoController = TextEditingController();
  final _valorController = TextEditingController();
  TipoVehiculo? _tipoVehiculo;
  Celda? _celda;
  DateTimeRange? _rango;

  @override
  void dispose() {
    _placaController.dispose();
    _propietarioNombreController.dispose();
    _propietarioTelefonoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _elegirRango() async {
    final ahora = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: ahora.subtract(const Duration(days: 365)),
      lastDate: ahora.add(const Duration(days: 730)),
      initialDateRange: _rango,
    );
    if (rango == null) return;
    setState(() => _rango = rango);
  }

  Future<void> _submit() async {
    final formValido = _formKey.currentState!.validate();
    final rango = _rango;
    // El date range picker ya garantiza `end >= start`, pero no `>` estricto
    // (se puede elegir el mismo día dos veces): el backend exige
    // `fechaFin > fechaInicio`, así que se valida acá también.
    final rangoValido = rango != null && rango.end.isAfter(rango.start);
    if (!formValido || _tipoVehiculo == null || !rangoValido) {
      if (_tipoVehiculo == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Selecciona un tipo de vehículo.')));
      } else if (!rangoValido) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona un rango de fechas válido: la fecha final debe ser posterior a la inicial.'),
          ),
        );
      }
      return;
    }

    final placaTecleada = _placaController.text.trim().toUpperCase();
    final mensualidad = await ref
        .read(nuevaMensualidadNotifierProvider.notifier)
        .crear(
          placa: placaTecleada,
          tipoVehiculo: _tipoVehiculo!,
          propietarioNombre: _propietarioNombreController.text.trim(),
          propietarioTelefono: _propietarioTelefonoController.text.trim(),
          celdaId: _celda?.id,
          fechaInicio: rango.start,
          fechaFin: rango.end,
          valorMensualidad: int.parse(_valorController.text.trim()),
        );
    if (mensualidad == null || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mensualidad creada'),
        // La respuesta no trae la placa (solo vehiculoId): se usa la que se
        // tecleó en el formulario.
        content: Text('Mensualidad registrada para la placa $placaTecleada.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Aceptar')),
        ],
      ),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = ref.watch(sessionNotifierProvider).usuario?.rol == RolUsuario.admin;
    if (!esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nueva mensualidad')),
        body: const AccesoRestringido(),
      );
    }

    final state = ref.watch(nuevaMensualidadNotifierProvider);
    final celdas = ref.watch(celdaListNotifierProvider).celdas;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva mensualidad')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'Si la placa ya existe, se reutilizará el vehículo registrado — el tipo y el '
                    'propietario solo aplican si es una placa nueva.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _placaController,
                  enabled: !state.isLoading,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    UpperCaseTextFormatter(),
                  ],
                  decoration: const InputDecoration(labelText: 'Placa'),
                  validator: placaValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<TipoVehiculo>(
                  initialValue: _tipoVehiculo,
                  decoration: const InputDecoration(labelText: 'Tipo de vehículo'),
                  items: [
                    for (final tipo in TipoVehiculo.values)
                      DropdownMenuItem(value: tipo, child: Text(tipoVehiculoLabel(tipo))),
                  ],
                  onChanged: state.isLoading ? null : (value) => setState(() => _tipoVehiculo = value),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _propietarioNombreController,
                  enabled: !state.isLoading,
                  decoration: const InputDecoration(labelText: 'Nombre del propietario (opcional)'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _propietarioTelefonoController,
                  enabled: !state.isLoading,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono del propietario (opcional)'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<Celda?>(
                  initialValue: _celda,
                  decoration: const InputDecoration(labelText: 'Celda asignada (opcional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Sin celda asignada')),
                    for (final celda in celdas)
                      DropdownMenuItem(value: celda, child: Text('${celda.codigo} · ${celda.zona}')),
                  ],
                  onChanged: state.isLoading ? null : (value) => setState(() => _celda = value),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: state.isLoading ? null : _elegirRango,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _rango != null
                        ? '${DateFormat('d MMM y', 'es_CO').format(_rango!.start)} – '
                              '${DateFormat('d MMM y', 'es_CO').format(_rango!.end)}'
                        : 'Selecciona el rango de fechas',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _valorController,
                  enabled: !state.isLoading,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Valor de la mensualidad'),
                  validator: requiredIntegerValidator,
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
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading ? const ButtonSpinner() : const Text('Crear mensualidad'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
