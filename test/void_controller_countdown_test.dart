import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_void_app/controllers/void_controller.dart';
import 'package:the_void_app/models/void_state.dart';

void main() {
  test('VoidController countdown decrements once per second until voided', () {
    fakeAsync((async) {
      final controller = VoidController();
      addTearDown(controller.dispose);

      controller.startListening();
      expect(controller.state.status, VoidState.listening);
      expect(controller.state.session, isNotNull);

      controller.stopListening();
      expect(controller.state.status, VoidState.transcribing);

      controller.startCountdown();
      expect(controller.state.status, VoidState.countdown);
      expect(controller.state.session?.countdownSeconds, 10);

      // After 1 second: 9
      async.elapse(const Duration(seconds: 1));
      expect(controller.state.session?.countdownSeconds, 9);

      // After 8 more seconds: 1
      async.elapse(const Duration(seconds: 8));
      expect(controller.state.session?.countdownSeconds, 1);

      // After 1 more second: note voided (and session wiped)
      async.elapse(const Duration(seconds: 1));
      expect(controller.state.status, VoidState.voided);
      expect(controller.state.session, isNull);
    });
  });

  test('countdownSecondsProvider emits updated values during countdown', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(voidControllerProvider.notifier);
      notifier.startListening();
      notifier.stopListening();
      notifier.startCountdown();

      expect(container.read(countdownSecondsProvider), 10);

      async.elapse(const Duration(seconds: 1));
      expect(container.read(countdownSecondsProvider), 9);
    });
  });
}

