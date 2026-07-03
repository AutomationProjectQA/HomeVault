import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/home_repository.dart';
import '../../features/assets/add_asset_screen.dart';
import '../../features/assets/asset_detail_screen.dart';
import '../../features/assets/assets_list_screen.dart';
import '../../features/bills/add_bill_screen.dart';
import '../../features/bills/bills_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/family/family_screen.dart';
import '../../features/onboarding/create_home_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/settings/privacy_policy_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/app_shell.dart';

abstract final class Routes {
  static const dashboard = '/';
  static const assets = '/assets';
  static const addAsset = '/assets/add';
  static const bills = '/bills';
  static const addBill = '/bills/add';
  static const settings = '/settings';
  static const welcome = '/welcome';
  static const createHome = '/welcome/create-home';
  static const privacy = '/privacy';
  static const family = '/family';

  static String assetDetail(String id) => '/assets/$id';
  static String editAsset(String id) => '/assets/$id/edit';
  static String editBill(String id) => '/bills/$id/edit';
}

final routerProvider = Provider<GoRouter>((ref) {
  final homeAsync = ref.watch(currentHomeProvider);

  return GoRouter(
    initialLocation: Routes.dashboard,
    redirect: (context, state) {
      // Home state still loading from the local DB: hold on splash.
      if (homeAsync.isLoading) return null;

      final hasHome = homeAsync.value != null;
      final location = state.matchedLocation;
      final inOnboarding = location.startsWith(Routes.welcome);
      final isNeutral = location == Routes.privacy;

      if (!hasHome && !inOnboarding && !isNeutral) return Routes.welcome;
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
      GoRoute(
        path: Routes.privacy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: Routes.family,
        builder: (context, state) => const FamilyScreen(),
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
              path: Routes.assets,
              builder: (context, state) => const AssetsListScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  parentNavigatorKey: null,
                  builder: (context, state) => const AddAssetScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => AssetDetailScreen(
                      assetId: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) => AddAssetScreen(
                          assetId: state.pathParameters['id']),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.bills,
              builder: (context, state) => const BillsScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const AddBillScreen(),
                ),
                GoRoute(
                  path: ':id/edit',
                  builder: (context, state) =>
                      AddBillScreen(billId: state.pathParameters['id']),
                ),
              ],
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
