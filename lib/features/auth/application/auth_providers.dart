import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/services/auth_service.dart';
import 'package:kith/data/services/google_sign_in_service.dart';

/// The app's [AuthService].
///
/// Deliberately has no default: the composition root overrides it with the
/// Firebase implementation, and tests override it with a fake. Reading it
/// unoverridden throws rather than silently authenticating against nothing.
final authServiceProvider = Provider<AuthService>((ref) {
  throw UnimplementedError(
    'authServiceProvider must be overridden with an AuthService '
    'implementation before it is read.',
  );
});

/// The app's [GoogleSignInService].
///
/// The same instance the auth service signs in through, so asking for the
/// calendar scope later happens against the account already signed in rather
/// than through a second session of its own. Deliberately has no default, for
/// the same reason [authServiceProvider] has none.
final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  throw UnimplementedError(
    'googleSignInServiceProvider must be overridden with a '
    'GoogleSignInService implementation before it is read.',
  );
});

/// The signed-in identity over time, null when signed out.
///
/// Stays `AsyncLoading` until the backend reports its first value, which is
/// how route guards tell "still restoring the session" apart from "signed
/// out" on cold start.
final authStateChangesProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

/// The signed-in identity right now, or null when signed out *or* still
/// loading. Guards that must distinguish the two watch
/// [authStateChangesProvider] instead.
final currentUserProvider = Provider<AuthUser?>(
  (ref) => ref.watch(authStateChangesProvider).value,
);
