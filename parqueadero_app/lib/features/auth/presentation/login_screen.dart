import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/error_banner.dart';
import 'login_controller.dart';

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Borde de foco de ambos campos (skill `diseno-parqueadero`): el foco es un
/// evento de interacción del operador, así que se tiñe de `demarcacion` en
/// vez del `verdeSenal` genérico del tema.
final _focusedBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(AppRadius.sm),
  borderSide: const BorderSide(color: AppColors.demarcacion, width: 2),
);

/// Borde en reposo del campo de correo: `linea`, el tono neutro de divisores.
final _lineaBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(AppRadius.sm),
  borderSide: const BorderSide(color: AppColors.linea, width: 1),
);

/// Borde en reposo del campo de contraseña: `demarcacion` más fino que el de
/// foco, para diferenciarlo sutilmente del de correo ya que es el campo con
/// el ícono de mostrar/ocultar.
final _demarcacionBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(AppRadius.sm),
  borderSide: const BorderSide(color: AppColors.demarcacion, width: 1.5),
);

/// Alto fijo del panel de marca cuando se apila arriba del formulario
/// (< [AppBreakpoints.tablet]): compacto a propósito, las mismas líneas
/// diagonales de [_MarcaPanel] quedan solo parcialmente visibles.
const _alturaMarcaCompacta = 192.0;

/// Nunca importa dio ni construye URLs: solo lee [loginControllerProvider] y
/// dispara [LoginController.submit]. La navegación a `/home` ocurre sola,
/// como efecto de que el router reacciona al cambio de estado de sesión.
///
/// A diferencia del resto de la app (skill `diseno-parqueadero`: la audacia
/// se concentra solo en la cuadrícula de celdas), esta pantalla sí lleva un
/// panel de marca completo — es la primera impresión del producto, antes de
/// que el operador vea una sola celda, y así lo pidió explícitamente el
/// rediseño de esta pantalla.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(loginControllerProvider.notifier)
        .submit(email: _emailController.text.trim(), password: _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final formulario = _Formulario(
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      obscurePassword: _obscurePassword,
      onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
      state: state,
      onSubmit: _submit,
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= AppBreakpoints.tablet) {
              return Row(
                key: const ValueKey('loginLayoutAncho'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(flex: 11, child: _MarcaPanel()),
                  Expanded(
                    flex: 10,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
                          child: formulario,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              key: const ValueKey('loginLayoutAngosto'),
              child: Column(
                children: [
                  const SizedBox(width: double.infinity, height: _alturaMarcaCompacta, child: _MarcaPanel()),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
                        child: formulario,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Panel izquierdo/superior de marca: fondo `asfalto` con las líneas de
/// demarcación de [_LineasDemarcacionPainter], ícono + nombre arriba, título
/// y bajada abajo. Un solo widget para ambos layouts — en el apilado queda
/// recortado por la altura fija de su contenedor, no por una variante propia.
class _MarcaPanel extends StatelessWidget {
  const _MarcaPanel();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _LineasDemarcacionPainter(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_parking, color: AppColors.demarcacion, size: 22),
                SizedBox(width: AppSpacing.sm),
                Text('Parqueadero', style: TextStyle(color: AppColors.demarcacion, fontSize: 15)),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Control total de tu operación,\ncelda por celda.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.concreto, height: 1.3),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Entradas, salidas y cobros en un solo lugar.',
                  style: TextStyle(color: AppColors.demarcacion.withValues(alpha: 0.8), fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fondo del panel de marca: relleno `asfalto` + 3 líneas diagonales en
/// `demarcacion` con opacidad decreciente, como demarcación pintada cruzando
/// el panel de esquina a esquina. Mismo recurso que `_HatchPainter` de
/// `celda_card.dart` (`Canvas.drawLine`), patrón constante — nunca depende de
/// props que cambien, así que nunca necesita repintarse a sí mismo.
class _LineasDemarcacionPainter extends CustomPainter {
  const _LineasDemarcacionPainter();

  static const _grosor = 26.0;
  static const _opacidades = [0.9, 0.55, 0.28];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.asfalto);

    final raya = Paint()..strokeWidth = _grosor;
    for (var i = 0; i < _opacidades.length; i++) {
      final dx = size.width * 0.28 * i;
      canvas.drawLine(
        Offset(-size.width * 0.1 + dx, size.height * 1.1),
        Offset(size.width * 0.45 + dx, -size.height * 0.1),
        raya..color = AppColors.demarcacion.withValues(alpha: _opacidades[i]),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineasDemarcacionPainter oldDelegate) => false;
}

/// El formulario en sí, sin nada de layout responsive: lo posiciona quien lo
/// use ([_LoginScreenState.build]) según el ancho disponible.
class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.state,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final LoginState state;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Iniciar sesión',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.asfalto, fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: emailController,
            enabled: !state.isLoading,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: 'Correo',
              enabledBorder: _lineaBorder,
              focusedBorder: _focusedBorder,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Ingresa tu correo';
              if (!_emailRegex.hasMatch(value.trim())) return 'Ingresa un correo válido';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: passwordController,
            enabled: !state.isLoading,
            obscureText: obscurePassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Contraseña',
              enabledBorder: _demarcacionBorder,
              focusedBorder: _focusedBorder,
              suffixIcon: IconButton(
                icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: onToggleObscure,
              ),
            ),
            validator: (value) => (value == null || value.isEmpty) ? 'Ingresa tu contraseña' : null,
            onFieldSubmitted: (_) => onSubmit(),
          ),
          if (state.error != null) ...[const SizedBox(height: AppSpacing.md), ErrorBanner(error: state.error!)],
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.asfalto, foregroundColor: AppColors.demarcacion),
            onPressed: state.isLoading ? null : onSubmit,
            child: state.isLoading
                ? const ButtonSpinner(color: AppColors.demarcacion)
                : const Text('Ingresar'),
          ),
        ],
      ),
    );
  }
}
