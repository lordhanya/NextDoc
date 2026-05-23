import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_page.dart';
import '../../features/recent/recent_page.dart';
import '../../features/tools/tools_page.dart';
import '../../features/settings/settings_page.dart';
import '../widgets/app_scaffold.dart';

abstract final class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: '/recent',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RecentPage(),
            ),
          ),
          GoRoute(
            path: '/tools',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ToolsPage(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
        ],
      ),
    ],
  );
}
