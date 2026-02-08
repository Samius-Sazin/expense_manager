import 'dart:async';

import 'package:expense_manager/app_config.dart';
import 'package:expense_manager/route/app_route.dart';
import 'package:expense_manager/route/model/route_key.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  // runZonedGuarded: Prevent crashing the app
  runZonedGuarded(
    () {
      runApp(const ProviderScope(child: ExpenseManagerApp()));
    },
    (error, stack) {},
    // Handle all print in the app, and only print in debug mode
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        parent.print(zone, kDebugMode ? 'DEBUG: $line' : '');
      },
    ),
  );
}

class ExpenseManagerApp extends HookConsumerWidget {
  const ExpenseManagerApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigatorKey = useRef(appNavigatorKey);
    final GoRouter appRouter = useMemoized(() {
      return GoRouter(
        navigatorKey: navigatorKey.value,
        routes: appRoutes,
        initialLocation: RouteKey.home,
      );
    });

    return MaterialApp.router(
      title: 'Xpense',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      builder: (BuildContext context, Widget? child) {
        AppConfig.bottomPadding = MediaQuery.of(context).padding.bottom;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(),
          child: child ?? SizedBox.shrink(),
        );
      },
    );
  }
}
