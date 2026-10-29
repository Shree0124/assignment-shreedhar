import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/visitors/presentation/dashboard/dashboard_screen.dart';
import '../../features/visitors/presentation/details/visitor_details_screen.dart';
import '../../features/visitors/presentation/form/visitor_form_screen.dart';
import '../../features/visitors/presentation/list/visitor_list_screen.dart';
import '../../features/visitors/presentation/scanner/qr_scanner_screen.dart';
import '../widgets/empty_state_widget.dart';
import 'app_shell.dart';

class AppRoutes {
  const AppRoutes._();

  static const dashboard = '/dashboard';
  static const visitors = '/visitors';
  static const scan = '/scan';
  static const visitorNew = '/visitors/new';

  static String visitorDetails(String id) =>
      '/visitors/${Uri.encodeComponent(id)}';

  static String visitorEdit(String id) =>
      '/visitors/${Uri.encodeComponent(id)}/edit';
}

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visitor Management')),
        body: EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Page not found',
          message: 'There is no screen for ${state.uri}.',
        ),
      );
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.visitors,
                builder: (context, state) => const VisitorListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const VisitorFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      return VisitorDetailsScreen(
                        visitorId: state.pathParameters['id']!,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          return VisitorFormScreen(
                            visitorId: state.pathParameters['id'],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.scan,
                builder: (context, state) => const QrScannerScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
