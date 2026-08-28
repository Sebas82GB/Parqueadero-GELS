import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/rol_usuario_label.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/acceso_restringido.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/session_notifier.dart';
import 'nuevo_usuario_notifier.dart';

class NuevoUsuarioScreen extends ConsumerStatefulWidget {
  const NuevoUsuarioScreen({super.key});

  @override
  ConsumerState<NuevoUsuarioScreen> createState() => _NuevoUsuarioScreenState();
}

class _NuevoUsuarioScreenState extends ConsumerState<NuevoUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  RolUsuario _rol = RolUsuario.operador;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final usuario = await ref
        .read(nuevoUsuarioNotifierProvider.notifier)
        .crear(
          nombre: _nombreController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rol: _rol,
        );
    if (usuario == null || !mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = ref.watch(sessionNotifierProvider).usuario?.rol == RolUsuario.admin;
    if (!esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nuevo usuario')),
        body: const AccesoRestringido(),
      );
    }

    final state = ref.watch(nuevoUsuarioNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo usuario')),
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
                  enabled: !state.isLoading,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: requiredValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _emailController,
                  enabled: !state.isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: emailValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  enabled: !state.isLoading,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  validator: (value) => (value == null || value.length < 8)
                      ? 'Debe tener al menos 8 caracteres'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<RolUsuario>(
                  initialValue: _rol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: [
                    for (final rol in RolUsuario.values)
                      DropdownMenuItem(value: rol, child: Text(rolUsuarioLabel(rol))),
                  ],
                  onChanged: state.isLoading ? null : (value) => setState(() => _rol = value!),
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
                  child: state.isLoading ? const ButtonSpinner() : const Text('Crear usuario'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
