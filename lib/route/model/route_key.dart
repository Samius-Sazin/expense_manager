class RouteKey {
  const RouteKey._();

  static const List<String> mainPathList = [
    RouteKey.home,
    RouteKey.analytics,
    RouteKey.settings,
  ];

  static const String home = '/home';

  static const String analytics = '/analytics';

  static const String settings = '/settings';
}
