import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/router/auth_route_guard.dart';
import 'package:uts/features/auth/domain/entities/user_entity.dart';

AuthUser userWithRole(UserRole role) => AuthUser(
      id: role.name,
      email: '${role.name}@example.test',
      role: role,
      isEmailVerified: true,
      isActive: true,
    );

void main() {
  group('AuthRouteGuard RBAC', () {
    test('User cannot open staff or admin routes', () {
      final user = userWithRole(UserRole.user);

      for (final route in [
        AuthRouteGuard.staffDashboard,
        AuthRouteGuard.ticketManagement,
        AuthRouteGuard.adminReports,
        AuthRouteGuard.adminSettings,
        AuthRouteGuard.userManagement,
      ]) {
        expect(
          AuthRouteGuard.redirect(
            status: AuthStatus.authenticated,
            user: user,
            location: route,
          ),
          AuthRouteGuard.dashboard,
        );
      }
    });

    test('Helpdesk cannot open Admin-only routes', () {
      final helpdesk = userWithRole(UserRole.technician);

      for (final route in [
        AuthRouteGuard.adminReports,
        AuthRouteGuard.adminSettings,
        AuthRouteGuard.userManagement,
      ]) {
        expect(
          AuthRouteGuard.redirect(
            status: AuthStatus.authenticated,
            user: helpdesk,
            location: route,
          ),
          AuthRouteGuard.staffDashboard,
        );
      }
    });

    test('Admin can open user management', () {
      expect(
        AuthRouteGuard.redirect(
          status: AuthStatus.authenticated,
          user: userWithRole(UserRole.admin),
          location: AuthRouteGuard.userManagement,
        ),
        isNull,
      );
    });
  });

  group('AuthRouteGuard deep links', () {
    test('authenticated user on splash is routed to role home', () {
      expect(
        AuthRouteGuard.redirect(
          status: AuthStatus.authenticated,
          user: userWithRole(UserRole.user),
          location: AuthRouteGuard.splash,
        ),
        AuthRouteGuard.dashboard,
      );

      expect(
        AuthRouteGuard.redirect(
          status: AuthStatus.authenticated,
          user: userWithRole(UserRole.technician),
          location: AuthRouteGuard.splash,
        ),
        AuthRouteGuard.staffDashboard,
      );
    });

    test('unauthenticated and error splash states route safely to login', () {
      expect(
        AuthRouteGuard.redirect(
          status: AuthStatus.unauthenticated,
          user: AuthUser.empty,
          location: AuthRouteGuard.splash,
        ),
        AuthRouteGuard.login,
      );

      expect(
        AuthRouteGuard.redirect(
          status: AuthStatus.error,
          user: AuthUser.empty,
          location: AuthRouteGuard.splash,
        ),
        AuthRouteGuard.login,
      );
    });

    test('unauthenticated route is preserved in encoded login redirect', () {
      expect(
        AuthRouteGuard.redirect(
          status: AuthStatus.unauthenticated,
          user: AuthUser.empty,
          location: '/tickets/abc',
        ),
        '/login?from=%2Ftickets%2Fabc',
      );
    });

    test('forbidden from route is discarded after login', () {
      expect(
        AuthRouteGuard.redirect(
          status: AuthStatus.authenticated,
          user: userWithRole(UserRole.user),
          location: AuthRouteGuard.login,
          from: AuthRouteGuard.userManagement,
        ),
        AuthRouteGuard.dashboard,
      );
    });

    test('external redirect target is discarded', () {
      expect(
        AuthRouteGuard.safeFrom(
          'https://malicious.example/path',
          UserRole.admin,
        ),
        isNull,
      );
    });

    test('password recovery always routes to change password', () {
      expect(
        AuthRouteGuard.redirect(
          status: AuthStatus.passwordRecovery,
          user: AuthUser.empty,
          location: AuthRouteGuard.login,
        ),
        AuthRouteGuard.changePassword,
      );
    });
  });
}
