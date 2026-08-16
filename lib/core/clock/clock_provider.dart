import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The single source of "now" for the whole app.
///
/// Every time-dependent calculation (freshness gauge, suggestion scoring,
/// hangout defaults) reads the clock through this provider so tests can pin
/// the current instant with `Clock.fixed`. Calling `DateTime.now()` directly
/// anywhere under `lib/` is a bug.
final clockProvider = Provider<Clock>((ref) => const Clock());

/// The current instant, derived from [clockProvider].
final nowProvider = Provider<DateTime>((ref) => ref.watch(clockProvider).now());
