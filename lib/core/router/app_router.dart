import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/pages/login_page.dart';
import 'package:uts/features/auth/presentation/pages/register_page.dart';
import 'package:uts/features/auth/presentation/pages/reset_password_page.dart';
import 'package:uts/features/auth/presentation/pages/splash_page.dart';
import 'package:uts/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:uts/features/ticket/presentation/pages/create_ticket_page.dart';
import 'package:uts/features/ticket/presentation/pages/ticket_detail_page.dart';
import 'package:uts/features/ticket/presentation/pages/ticket_list_page.dart';
import 'package:uts/features/ticket/presentation/pages/history_page.dart';

/// Named route constants untuk type-safe navigation.
abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String resetPassword = '/reset-password';
  static const String dashboard = '/dashboard';
  static const String tickets = '/tickets';
  static const String createTicket = '/tickets/create';
  static const String ticketDetail = '/tickets/:id';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String history = '/history';
  static const String staffDashboard = '/staff-dashboard';
}

/// Konfigurasi GoRouter — navigasi deklaratif.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  errorBuilder: (context, state) => _ErrorPage(error: state.error),
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final bool loggingIn = state.matchedLocation == AppRoutes.login || 
                          state.matchedLocation == AppRoutes.register ||
                          state.matchedLocation == AppRoutes.resetPassword ||
                          state.matchedLocation == AppRoutes.splash;

    if (authState.status == AuthStatus.authenticated) {
      final role = authState.user.role;
      final isStaff = role == UserRole.admin || role == UserRole.technician;
      
      // If user is already logged in and tries to go to login/splash, redirect to dashboard
      if (loggingIn) {
        return isStaff ? AppRoutes.staffDashboard : AppRoutes.dashboard;
      }
      
      // Guard: Role 3 (Customer) cannot access /staff-dashboard
      if (state.matchedLocation == AppRoutes.staffDashboard && !isStaff) {
        return AppRoutes.dashboard;
      }
    } else if (authState.status == AuthStatus.unauthenticated) {
      if (!loggingIn) return AppRoutes.login;
    }
    return null;
  },
  routes: [
    // ── Splash ──────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),

    // ── Auth ─────────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: LoginPage(),
        transitionsBuilder: _fadeTransition,
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

    // ── Main App ─────────────────────────────────────────────────────────────
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
      routes: [
        GoRoute(
          path: 'create',
          name: 'create-ticket',
          pageBuilder: (context, state) => const CustomTransitionPage(
            child: CreateTicketPage(),
            transitionsBuilder: _slideUpTransition,
          ),
        ),
        GoRoute(
          path: ':id',
          name: 'ticket-detail',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return CustomTransitionPage(
              child: TicketDetailPage(ticketId: id),
              transitionsBuilder: _slideTransition,
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.history,
      name: 'history',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: HistoryPage(),
        transitionsBuilder: _slideTransition,
      ),
    ),
  ],
);

// ── Transition helpers ────────────────────────────────────────────────────────

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

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

// ── Error Page ────────────────────────────────────────────────────────────────

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
            const Text('Halaman tidak ditemukan', style: TextStyle(fontSize: 18)),
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
