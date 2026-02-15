import 'dart:async';

import 'package:expense_manager/app_config.dart';
import 'package:expense_manager/route/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
