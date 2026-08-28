import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/home_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/session_notifier.dart';
import '../../features/auth/presentation/session_state.dart';
import '../../features/celdas/presentation/celda_detail_screen.dart';
import '../../features/celdas/presentation/celdas_screen.dart';
import '../../features/horarios/presentation/horarios_screen.dart';
import '../../features/horarios/presentation/nuevo_horario_screen.dart';
import '../../features/mensualidades/presentation/mensualidad_detail_screen.dart';
import '../../features/mensualidades/presentation/mensualidades_screen.dart';
import '../../features/mensualidades/presentation/nueva_mensualidad_screen.dart';
import '../../features/tarifas/presentation/nueva_tarifa_screen.dart';
import '../../features/tarifas/presentation/tarifas_screen.dart';
import '../../features/tickets/domain/ticket.dart';
import '../../features/tickets/presentation/buscar_placa_screen.dart';
import '../../features/tickets/presentation/recibo_screen.dart';
import '../../features/tickets/presentation/registrar_entrada_screen.dart';
import '../../features/tickets/presentation/registrar_salida_screen.dart';
import '../../features/tickets/presentation/ticket_detail_screen.dart';
import '../../features/tickets/presentation/tickets_historial_screen.dart';
import '../../features/turnos/presentation/abrir_turno_screen.dart';
import '../../features/turnos/presentation/turno_cierre_screen.dart';
import '../../features/turnos/presentation/turno_detail_screen.dart';
import '../../features/turnos/presentation/turnos_historial_screen.dart';
import '../../features/usuarios/presentation/nuevo_usuario_screen.dart';
import '../../features/usuarios/presentation/usuario_detail_screen.dart';
import '../../features/usuarios/presentation/usuarios_screen.dart';
import '../widgets/splash_screen.dart';

/// Puente entre Riverpod y `refreshListenable` de go_router (que espera un
/// `Listenable` clásico): cada cambio de [sessionNotifierProvider] hace que
/// go_router vuelva a evaluar `redirect`.
class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen(sessionNotifierProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final session = ref.read(sessionNotifierProvider);
      final path = state.matchedLocation;

      switch (session.status) {
        case SessionStatus.checking:
          return path == '/' ? null : '/';
        case SessionStatus.unauthenticated:
          return path == '/login' ? null : '/login';
        case SessionStatus.authenticated:
          return (path == '/' || path == '/login') ? '/home' : null;
      }
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/celdas', builder: (context, state) => const CeldasScreen()),
      GoRoute(
        path: '/celdas/:id',
        builder: (context, state) => CeldaDetailScreen(celdaId: state.pathParameters['id']!),
      ),
      // Rutas literales de /tickets declaradas ANTES que /tickets/:id: en
      // go_router los hermanos se resuelven en orden de declaración, no por
      // especificidad — si /tickets/:id fuera primero, /tickets/entrada
      // matchearía ahí con id = 'entrada'.
      GoRoute(path: '/tickets', builder: (context, state) => const TicketsHistorialScreen()),
      GoRoute(
        path: '/tickets/entrada',
        builder: (context, state) =>
            RegistrarEntradaScreen(celdaId: state.uri.queryParameters['celdaId']),
      ),
      GoRoute(path: '/tickets/buscar', builder: (context, state) => const BuscarPlacaScreen()),
      GoRoute(
        path: '/tickets/:id',
        builder: (context, state) => TicketDetailScreen(
          ticketId: state.pathParameters['id']!,
          ticketInicial: state.extra as Ticket?,
        ),
      ),
      GoRoute(
        path: '/tickets/:id/salida',
        builder: (context, state) => RegistrarSalidaScreen(ticketId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tickets/:id/recibo',
        builder: (context, state) => ReciboScreen(ticketId: state.pathParameters['id']!),
      ),
      // Mismo criterio de orden que /tickets: literales antes que /turnos/:id.
      GoRoute(path: '/turnos', builder: (context, state) => const TurnosHistorialScreen()),
      GoRoute(path: '/turnos/abrir', builder: (context, state) => const AbrirTurnoScreen()),
      GoRoute(
        path: '/turnos/:id',
        builder: (context, state) => TurnoDetailScreen(turnoId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/turnos/:id/cerrar',
        builder: (context, state) => TurnoCierreScreen(turnoId: state.pathParameters['id']!),
      ),
      // Misma regla de orden que /tickets: la ruta literal /tarifas/nueva
      // antes que /tarifas/:id... — acá no hay /tarifas/:id (la acción de
      // cerrar vigencia vive inline en el listado), pero se mantiene el
      // mismo criterio por consistencia.
      GoRoute(path: '/tarifas', builder: (context, state) => const TarifasScreen()),
      GoRoute(path: '/tarifas/nueva', builder: (context, state) => const NuevaTarifaScreen()),
      // Misma regla de orden que /tarifas: literal /horarios/nuevo antes de
      // cualquier ruta con parámetro (hoy no hay /horarios/:id).
      GoRoute(path: '/horarios', builder: (context, state) => const HorariosScreen()),
      GoRoute(path: '/horarios/nuevo', builder: (context, state) => const NuevoHorarioScreen()),
      GoRoute(path: '/mensualidades', builder: (context, state) => const MensualidadesScreen()),
      GoRoute(path: '/mensualidades/nueva', builder: (context, state) => const NuevaMensualidadScreen()),
      GoRoute(
        path: '/mensualidades/:id',
        builder: (context, state) =>
            MensualidadDetailScreen(mensualidadId: state.pathParameters['id']!),
      ),
      // Misma regla de orden: literal /usuarios/nuevo antes de /usuarios/:id.
      GoRoute(path: '/usuarios', builder: (context, state) => const UsuariosScreen()),
      GoRoute(path: '/usuarios/nuevo', builder: (context, state) => const NuevoUsuarioScreen()),
      GoRoute(
        path: '/usuarios/:id',
        builder: (context, state) => UsuarioDetailScreen(usuarioId: state.pathParameters['id']!),
      ),
    ],
  );
});
