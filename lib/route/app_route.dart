import 'package:expense_manager/analytics/ui/analytics_page.dart';
import 'package:expense_manager/common/ui/main_page.dart';
import 'package:expense_manager/home/ui/home_page.dart';
import 'package:expense_manager/route/model/route_key.dart';
import 'package:expense_manager/settings/ui/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/stateful_shell_route.dart

final _appNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'xpense');
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _analyticsNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'analytics',
);
final _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

final GoRouter appRouter = GoRouter(
  navigatorKey: _appNavigatorKey,
  initialLocation: RouteKey.home,
  routes: [
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
          navigatorKey: _homeNavigatorKey,
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
          navigatorKey: _analyticsNavigatorKey,
          routes: [
            GoRoute(
              path: RouteKey.analytics,
              builder: (context, state) => AnalyticsPage(),
            ),
          ],
        ),

        // analytics
        StatefulShellBranch(
          navigatorKey: _settingsNavigatorKey,
          routes: [
            GoRoute(
              path: RouteKey.settings,
              builder: (context, state) => SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

// final List<RouteBase> appRoutes = [
//   StatefulShellRoute.indexedStack(
//     builder:
//         (
//           BuildContext context,
//           GoRouterState state,
//           StatefulNavigationShell navigationShell,
//         ) {
//           return MainPage(navigationShell: navigationShell);
//         },
//     branches: <StatefulShellBranch>[
//       // Home
//       StatefulShellBranch(
//         navigatorKey: _homeNavigatorKey,
//         routes: [
//           GoRoute(
//             path: RouteKey.home,
//             builder: (context, state) => HomePage(),
//             routes: [],
//           ),
//         ],
//       ),

//       // analytics
//       StatefulShellBranch(
//         navigatorKey: _analyticsNavigatorKey,
//         routes: [
//           GoRoute(
//             path: RouteKey.analytics,
//             builder: (context, state) => AnalyticsPage(),
//           ),
//         ],
//       ),

//       // analytics
//       StatefulShellBranch(
//         navigatorKey: _settingsNavigatorKey,
//         routes: [
//           GoRoute(
//             path: RouteKey.settings,
//             builder: (context, state) => SettingsPage(),
//           ),
//         ],
//       ),
//     ],
//   ),
// ];
