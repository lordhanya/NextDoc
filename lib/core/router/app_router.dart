import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_page.dart';
import '../../features/recent/recent_page.dart';
import '../../features/tools/tools_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/tools/screens/merge_pdf_screen.dart';
import '../../features/tools/screens/compress_pdf_screen.dart';
import '../../features/tools/screens/image_to_pdf_screen.dart';
import '../../features/tools/screens/split_pdf_screen.dart';
import '../../features/tools/screens/processing_screen.dart';
import '../../features/tools/screens/success_screen.dart';
import '../../features/pdf/pdf_detail_screen.dart';
import '../widgets/app_scaffold.dart';

abstract final class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static Page<void> _slideUpTransition(BuildContext context, GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slide,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

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
      GoRoute(
        path: '/tools/merge',
        pageBuilder: (context, state) => _slideUpTransition(
          context,
          state,
          const MergePdfScreen(),
        ),
      ),
      GoRoute(
        path: '/tools/compress',
        pageBuilder: (context, state) => _slideUpTransition(
          context,
          state,
          const CompressPdfScreen(),
        ),
      ),
      GoRoute(
        path: '/tools/image-to-pdf',
        pageBuilder: (context, state) => _slideUpTransition(
          context,
          state,
          const ImageToPdfScreen(),
        ),
      ),
      GoRoute(
        path: '/tools/split',
        pageBuilder: (context, state) => _slideUpTransition(
          context,
          state,
          const SplitPdfScreen(),
        ),
      ),
      GoRoute(
        path: '/processing',
        pageBuilder: (context, state) => _slideUpTransition(
          context,
          state,
          const ProcessingScreen(),
        ),
      ),
      GoRoute(
        path: '/success',
        pageBuilder: (context, state) => _slideUpTransition(
          context,
          state,
          const SuccessScreen(),
        ),
      ),
      GoRoute(
        path: '/pdf-detail',
        pageBuilder: (context, state) => _slideUpTransition(
          context,
          state,
          PdfDetailScreen(
            filePath: state.extra is Map ? (state.extra as Map)['filePath'] as String : '',
            fileName: state.extra is Map ? (state.extra as Map)['fileName'] as String : '',
            fileSize: state.extra is Map ? (state.extra as Map)['fileSize'] as int : 0,
            pageCount: state.extra is Map ? (state.extra as Map)['pageCount'] as int : 0,
            heroTag: state.extra is Map ? (state.extra as Map)['heroTag'] as String : '',
          ),
        ),
      ),
    ],
  );
}
