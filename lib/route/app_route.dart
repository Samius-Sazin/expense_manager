import 'package:expense_manager/analytics/ui/analytics_page.dart';
import 'package:expense_manager/common/ui/main_page.dart';
import 'package:expense_manager/home/ui/home_page.dart';
import 'package:expense_manager/route/model/route_key.dart';
import 'package:expense_manager/settings/ui/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final appNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'xpense');
final homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final analyticsNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'analytics',
);
final settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

final List<RouteBase> appRoutes = [
  StatefulShellRoute.indexedStack(
    builder:
        (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return MainPage(navigationShell: navigationShell);
        },
    branches: <StatefulShellBranch>[
      // Home
      StatefulShellBranch(
        navigatorKey: homeNavigatorKey,
        routes: [
          GoRoute(
            path: RouteKey.home,
            builder: (context, state) => HomePage(),
            routes: [],
          ),
        ],
      ),

      // analytics
      StatefulShellBranch(
        navigatorKey: analyticsNavigatorKey,
        routes: [
          GoRoute(
            path: RouteKey.analytics,
            builder: (context, state) => AnalyticsPage(),
          ),
        ],
      ),

      // analytics
      StatefulShellBranch(
        navigatorKey: settingsNavigatorKey,
        routes: [
          GoRoute(
            path: RouteKey.settings,
            builder: (context, state) => SettingsPage(),
          ),
        ],
      ),
    ],
  ),
];
