import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/clock/clock_provider.dart';

void main() {
  group('clockProvider', () {
    test('defaults to the ambient system clock', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(clockProvider), isA<Clock>());
    });

    test('can be overridden with a fixed clock', () {
      final pinned = DateTime.utc(2026, 3, 14, 9, 26, 53);
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(Clock.fixed(pinned))],
      );
      addTearDown(container.dispose);

      expect(container.read(clockProvider).now(), pinned);
    });
  });

  group('nowProvider', () {
    test('reads the instant from clockProvider', () {
      final pinned = DateTime.utc(2026, 1, 2, 3, 4, 5);
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(Clock.fixed(pinned))],
      );
      addTearDown(container.dispose);

      expect(container.read(nowProvider), pinned);
    });

    test('tracks the ambient clock when not overridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final before = DateTime.now();
      final now = container.read(nowProvider);

      expect(
        now.isBefore(before.subtract(const Duration(seconds: 5))),
        isFalse,
      );
    });
  });
}
