import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parqueadero_app/features/celdas/presentation/reloj_notifier.dart';

void main() {
  test('el estado cambia cada 60s sin interacción del usuario', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(relojNotifierProvider, (_, _) {});

      final inicial = container.read(relojNotifierProvider);

      async.elapse(const Duration(seconds: 61));

      expect(container.read(relojNotifierProvider), isNot(inicial));
    });
  });

  test('al salir de la pantalla (dispose del container) el timer se cancela', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      container.listen(relojNotifierProvider, (_, _) {});
      async.elapse(const Duration(seconds: 61));

      container.dispose();

      // No debe lanzar ni seguir emitiendo tras el dispose: si el timer
      // siguiera vivo, este elapse dispararía un callback sobre un
      // ProviderContainer ya destruido.
      expect(() => async.elapse(const Duration(minutes: 5)), returnsNormally);
    });
  });
}
