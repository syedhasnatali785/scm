import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_state.dart';
import '../../features/onboarding/onboarding_state.dart';
import '../../ui/screens/auth_screen.dart';
import '../../ui/screens/onboarding_screen.dart';
import '../../ui/screens/import_command_center_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
    _ref.listen(onboardingProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final onboardingState = _ref.read(onboardingProvider);

    final isAuthenticated = authState.hasValue && authState.value != null;
    final isOnboarded = onboardingState.isOnboarded;
    final isAuthRoute = state.uri.path == '/auth';
    final isOnboardingRoute = state.uri.path == '/onboarding';

    if (!isAuthenticated) {
      return isAuthRoute ? null : '/auth';
    }

    if (isAuthenticated && !isOnboarded) {
      return isOnboardingRoute ? null : '/onboarding';
    }

    if (isAuthenticated && isOnboarded && (isAuthRoute || isOnboardingRoute)) {
      return '/command-center';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/command-center',
        builder: (context, state) => const ImportCommandCenterScreen(),
      ),
    ],
  );
});
