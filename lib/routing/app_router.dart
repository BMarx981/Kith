import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/features/auth/presentation/sign_in_screen.dart';
import 'package:kith/features/contacts/presentation/contacts_screen.dart';
import 'package:kith/features/suggestions/presentation/home_screen.dart';

part 'app_router.gr.dart';

/// The app's route graph.
///
/// Routes are declared here and nowhere else; navigation always goes through
/// the generated typed `*Route` classes rather than raw path strings. Auth and
/// household-membership guards attach in M1.
@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, path: '/', initial: true),
    AutoRoute(page: ContactsRoute.page, path: '/contacts'),
    AutoRoute(page: SignInRoute.page, path: '/sign-in'),
  ];
}

/// Holds the single [AppRouter] instance for the app's lifetime.
final appRouterProvider = Provider<AppRouter>((ref) => AppRouter());
