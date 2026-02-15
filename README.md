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

## Step 01: Setup Route with GoRouter

- Reference:
  - [Flutter Doc](https://pub.dev/documentation/go_router/latest/index.html)
  - [Example Code](https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/stateful_shell_route.dart)
  - [My Code First(Create Project and Setup GoRouter)](https://github.com/Samius-Sazin/expense_manager/tree/4929525e90800a0025d175dcbadd2db160fd97a5)
  - [My Code Second (Simplified the GoRouter setup)]()

1. Setup Route key in `route/route_key.dart`
2. Define routes in `route/app_route.dart`
3. Implement BottomNavigationBar in main_page.dart and call it from `app_route.dart`
4. In main.dart file, get the appRouter app_route.dart
5. Set up router tracker
6. `Optional` Create extension for clear all navigation stack and navigate to a new route.


