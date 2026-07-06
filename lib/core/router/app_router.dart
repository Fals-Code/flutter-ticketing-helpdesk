import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/di/injection_container.dart';
import 'package:uts/core/router/app_router_refresh_listenable.dart';
import 'package:uts/core/router/auth_route_guard.dart';
import 'package:uts/core/router/startup_gate.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/admin/presentation/pages/admin_reports_page.dart';
import 'package:uts/features/admin/presentation/pages/admin_settings_page.dart';
import 'package:uts/features/admin/presentation/pages/user_management_page.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/auth/presentation/pages/change_password_page.dart';
import 'package:uts/features/auth/presentation/pages/edit_profile_page.dart';
import 'package:uts/features/auth/presentation/pages/login_page.dart';
import 'package:uts/features/auth/presentation/pages/register_page.dart';
import 'package:uts/features/auth/presentation/pages/reset_password_page.dart';
import 'package:uts/features/auth/presentation/pages/splash_page.dart';
import 'package:uts/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:uts/features/ticket/presentation/pages/create_ticket_page.dart';
import 'package:uts/features/ticket/presentation/pages/history_page.dart';
import 'package:uts/features/ticket/presentation/pages/ticket_detail_page.dart';
import 'package:uts/features/ticket/presentation/pages/ticket_list_page.dart';
import 'package:uts/features/ticket/presentation/pages/ticket_tracking_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/tracking/ticket_tracking_event.dart';

abstract final class AppRoutes {
  static const String splash = AuthRouteGuard.splash;
  static const String login = AuthRouteGuard.login;
  static const String register = AuthRouteGuard.register;
  static const String resetPassword = AuthRouteGuard.resetPassword;
  static const String changePassword = AuthRouteGuard.changePassword;
  static const String dashboard = AuthRouteGuard.dashboard;
  static const String staffDashboard = AuthRouteGuard.staffDashboard;
  static const String ticketManagement = AuthRouteGuard.ticketManagement;
  static const String adminReports = AuthRouteGuard.adminReports;
  static const String adminSettings = AuthRouteGuard.adminSettings;
  static const String userManagement = AuthRouteGuard.userManagement;

  static const String tickets = '/tickets';
  static const String createTicket = AuthRouteGuard.createTicket;
  static const String ticketDetail = '/tickets/:id';
  static const String ticketTracking = '/tickets/:id/tracking';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String history = '/history';
}

GoRouter createAppRouter({
  required AuthBloc authBloc,
  required StartupGate startupGate,
  bool debugLogDiagnostics = true,
}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: debugLogDiagnostics,
    refreshListenable: GoRouterRefreshStream(
      authBloc.stream,
      listenables: [startupGate],
    ),
    errorBuilder: (context, state) => _ErrorPage(error: state.error),
    redirect: (context, state) {
      return resolveAppRedirect(
        authState: authBloc.state,
        location: state.matchedLocation,
        from: state.uri.queryParameters['from'],
        startupGate: startupGate,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: RegisterPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'reset-password',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: ResetPasswordPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'change-password',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: ChangePasswordPage(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: EditProfilePage(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: DashboardPage(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.staffDashboard,
        name: 'staff-dashboard',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: DashboardPage(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.tickets,
        name: 'tickets',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: TicketListPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.createTicket,
        name: 'create-ticket',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: CreateTicketPage(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.ticketTracking,
        name: 'ticket-tracking',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: BlocProvider(
            create: (_) => sl<TicketTrackingBloc>()
              ..add(LoadTicketTrackingRequested(
                state.pathParameters['id']!,
              )),
            child: TicketTrackingPage(
              ticketId: state.pathParameters['id']!,
            ),
          ),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.ticketDetail,
        name: 'ticket-detail',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: TicketDetailPage(ticketId: state.pathParameters['id']!),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: HistoryPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminReports,
        name: 'admin-reports',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: AdminReportsPage(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.ticketManagement,
        name: 'ticket-management',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: TicketListPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        name: 'admin-settings',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: AdminSettingsPage(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.userManagement,
        name: 'user-management',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: UserManagementPage(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
    ],
  );
}

String? resolveAppRedirect({
  required AuthState authState,
  required String location,
  required StartupGate startupGate,
  String? from,
}) {
  final isSplash = location == AppRoutes.splash;
  final isStartupPending = !startupGate.minimumRevealComplete;
  final isResolvingAuth = authState.status == AuthStatus.initial ||
      authState.status == AuthStatus.loading;

  if (isSplash) {
    if (isResolvingAuth || isStartupPending) {
      _debugStartupRedirect(
        location: location,
        status: authState.status,
        minimumRevealComplete: startupGate.minimumRevealComplete,
        result: null,
      );
      return null;
    }
  }

  final redirect = AuthRouteGuard.redirect(
    status: authState.status,
    user: authState.user,
    location: location,
    from: from,
  );
  _debugStartupRedirect(
    location: location,
    status: authState.status,
    minimumRevealComplete: startupGate.minimumRevealComplete,
    result: redirect,
  );
  return redirect;
}

void _debugStartupRedirect({
  required String location,
  required AuthStatus status,
  required bool minimumRevealComplete,
  required String? result,
}) {
  assert(() {
    debugPrint(
      'startup redirect location=$location status=$status gate=$minimumRevealComplete result=${result ?? 'stay'}',
    );
    return true;
  }());
}

GoRouter? _appRouterInstance;

GoRouter get appRouter => _appRouterInstance ??= createAppRouter(
      authBloc: sl<AuthBloc>(),
      startupGate: startupGate,
    );

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: child,
  );
}

Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: FadeTransition(opacity: animation, child: child),
  );
}

class _ErrorPage extends StatelessWidget {
  final Exception? error;

  const _ErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Halaman tidak ditemukan',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(error?.toString() ?? '', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.splash),
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    );
  }
}
