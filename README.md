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

### Change the app name and app icon

Need to run this command after setup everything for app icon
- [App Name](https://github.com/Samius-Sazin/expense_manager/tree/e02a7330c0bf8f42aa9d2b790a8ab913b3a44f64)
- [App Icon](https://github.com/Samius-Sazin/expense_manager/tree/79c1d4b073639ceec7427a09610ac39bf0768363)

```bash
dart run flutter_launcher_icons
```


## Step 01: Setup Route with GoRouter

- Reference:
  - [Flutter Doc](https://pub.dev/documentation/go_router/latest/index.html)
  - [Example Code](https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/stateful_shell_route.dart)
  - [My Code First(Create Project and Setup GoRouter)](https://github.com/Samius-Sazin/expense_manager/tree/4929525e90800a0025d175dcbadd2db160fd97a5)
  - [My Code Second (Simplify the GoRouter setup)](https://github.com/Samius-Sazin/expense_manager/tree/acb9ef3d08a4425e2b29074ecaa95af4fe0fd73d)

1. Setup Route key in `route/route_key.dart`
2. Define routes in `route/app_route.dart`
3. Implement BottomNavigationBar in main_page.dart and call it from `app_route.dart`
4. In main.dart file, get the appRouter app_route.dart
5. Set up router tracker
6. `Optional` Create extension for clear all navigation stack and navigate to a new route.

## Step 02: Setup State Management/Provider with Riverpod
