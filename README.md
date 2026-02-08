# Expense Manager Flutter Project

## Create the project.

```bash
flutter create project_name
```

## Create File Structures

```
lib/
├── home/
│   ├── ui/
│   ├── widget/
│   ├── util/
│   ├── data/
│   └── domain/
├── analytics/
├── settings/
├── common/
├── route/
├── theme/
└── translation/
```

## Setup Route with [GoRouter](https://pub.dev/documentation/go_router/latest/index.html)

1. Setup Route key in `route/route_key.dart`

2. Define routes in `route/app_route.dart`

3. Implement BottomNavigationBar in main_page.dart and call it from `app_route.dart`

4. In main.dart file, get the router instance from app_route.dart

   ```dart
   MaterialApp.router(
   routerConfig: GoRouter(
       navigatorKey: navigatorKey.value,
       routes: appRoutes,
       initialLocation: RouteKey.home,
       ),
   )
   ```
