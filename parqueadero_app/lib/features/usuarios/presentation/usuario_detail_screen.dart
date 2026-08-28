import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/rol_usuario_label.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/acceso_restringido.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/detail_skeleton.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/session_notifier.dart';
import 'usuario_detail_notifier.dart';
import 'usuario_list_notifier.dart';

/// Ruta completa (deep-linkable), no bottom sheet. Lee el usuario de
/// [usuarioListNotifierProvider] por id — mismo patrón que
/// `MensualidadDetailScreen` — y expone un formulario de edición completo:
/// nombre, email, password (opcional, en blanco no la cambia), rol,
/// activo/inactivo y baseInicialTurno (solo visible si el rol elegido es
/// ADMIN, sin importar el rol original del usuario).
class UsuarioDetailScreen extends ConsumerStatefulWidget {
  const UsuarioDetailScreen({super.key, required this.usuarioId});

  final String usuarioId;

  @override
  ConsumerState<UsuarioDetailScreen> createState() => _UsuarioDetailScreenState();
}

class _UsuarioDetailScreenState extends ConsumerState<UsuarioDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _baseInicialController = TextEditingController();
  RolUsuario? _rol;
  bool _activo = true;
  bool _inicializado = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _baseInicialController.dispose();
    super.dispose();
  }

  void _inicializarDesde(Usuario usuario) {
    _nombreController.text = usuario.nombre;
    _emailController.text = usuario.email;
    _rol = usuario.rol;
    _activo = usuario.activo;
    _baseInicialController.text = usuario.baseInicialTurno?.toString() ?? '';
    _inicializado = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final rol = _rol!;
    final baseInicialTexto = _baseInicialController.text.trim();

    final ok = await ref
        .read(usuarioDetailNotifierProvider(widget.usuarioId).notifier)
        .guardar(
          nombre: _nombreController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.isEmpty ? null : _passwordController.text,
          rol: rol,
          activo: _activo,
          baseInicialTurno: rol == RolUsuario.admin && baseInicialTexto.isNotEmpty
              ? int.parse(baseInicialTexto)
              : null,
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cambios guardados.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = ref.watch(sessionNotifierProvider).usuario?.rol == RolUsuario.admin;
    if (!esAdmin) {
      return Scaffold(appBar: AppBar(), body: const AccesoRestringido());
    }

    final listState = ref.watch(usuarioListNotifierProvider);
    Usuario? usuario;
    for (final u in listState.usuarios) {
      if (u.id == widget.usuarioId) {
        usuario = u;
        break;
      }
    }

    if (usuario == null) {
      Widget body;
      if (listState.isLoading) {
        body = const DetailSkeleton();
      } else if (listState.errorMessage != null) {
        body = ErrorState(
          message: listState.errorMessage!,
          onRetry: ref.read(usuarioListNotifierProvider.notifier).refrescar,
        );
      } else {
        body = const EmptyState(icon: Icons.search_off, message: 'Usuario no encontrado.');
      }
      return Scaffold(appBar: AppBar(), body: body);
    }

    if (!_inicializado) _inicializarDesde(usuario);
    final detalle = ref.watch(usuarioDetailNotifierProvider(widget.usuarioId));
    final rolSeleccionado = _rol!;

    return Scaffold(
      appBar: AppBar(title: Text(usuario.nombre)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombreController,
                  enabled: !detalle.isLoading,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: requiredValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _emailController,
                  enabled: !detalle.isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: emailValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  enabled: !detalle.isLoading,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña',
                    helperText: 'Deja en blanco para no cambiarla',
                  ),
                  validator: (value) =>
                      (value != null && value.isNotEmpty && value.length < 8)
                      ? 'Debe tener al menos 8 caracteres'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<RolUsuario>(
                  initialValue: rolSeleccionado,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: [
                    for (final rol in RolUsuario.values)
                      DropdownMenuItem(value: rol, child: Text(rolUsuarioLabel(rol))),
                  ],
                  onChanged: detalle.isLoading ? null : (value) => setState(() => _rol = value!),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo'),
                  value: _activo,
                  onChanged: detalle.isLoading ? null : (value) => setState(() => _activo = value),
                ),
                if (rolSeleccionado == RolUsuario.admin) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _baseInicialController,
                    enabled: !detalle.isLoading,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Base inicial para turno automático',
                      helperText:
                          'La usa el turno automático al abrir sin que el operador la digite. '
                          'En blanco: este ADMIN no participa en la apertura automática.',
                    ),
                  ),
                ],
                if (detalle.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    detalle.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: detalle.isLoading ? null : _submit,
                  child: detalle.isLoading ? const ButtonSpinner() : const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
