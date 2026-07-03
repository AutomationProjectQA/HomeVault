import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/home_repository.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/onboarding/create_home_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/app_shell.dart';

abstract final class Routes {
  static const dashboard = '/';
  static const settings = '/settings';
  static const welcome = '/welcome';
  static const createHome = '/welcome/create-home';
}

final routerProvider = Provider<GoRouter>((ref) {
  final homeAsync = ref.watch(currentHomeProvider);

  return GoRouter(
    initialLocation: Routes.dashboard,
    redirect: (context, state) {
      // Home state still loading from the local DB: hold on splash.
      if (homeAsync.isLoading) return null;

      final hasHome = homeAsync.value != null;
      final inOnboarding = state.matchedLocation.startsWith(Routes.welcome);

      if (!hasHome && !inOnboarding) return Routes.welcome;
      if (hasHome && inOnboarding) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'create-home',
            builder: (context, state) => const CreateHomeScreen(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.dashboard,
              builder: (context, state) => homeAsync.isLoading
                  ? const _Splash()
                  : const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
