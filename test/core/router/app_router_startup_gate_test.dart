import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/core/router/auth_route_guard.dart';
import 'package:uts/core/router/startup_gate.dart';
import 'package:uts/features/auth/domain/entities/user_entity.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';

AuthUser _user(UserRole role) => AuthUser(
      id: role.name,
      email: '${role.name}@example.test',
      role: role,
      isEmailVerified: true,
      isActive: true,
    );

void main() {
  group('startup routing gate', () {
    late StartupGate gate;

    setUp(() {
      gate = StartupGate();
    });

    test('route name splash tetap memakai path /', () {
      expect(AppRoutes.splash, '/');
      expect(AuthRouteGuard.splash, '/');
    });

    test('auth initial tetap di splash', () {
      expect(
        resolveAppRedirect(
          authState: const AuthState(status: AuthStatus.initial),
          location: AppRoutes.splash,
          startupGate: gate,
        ),
        isNull,
      );
    });

    test('auth loading tetap di splash', () {
      expect(
        resolveAppRedirect(
          authState: const AuthState(status: AuthStatus.loading),
          location: AppRoutes.splash,
          startupGate: gate,
        ),
        isNull,
      );
    });

    test('auth unauthenticated sebelum gate selesai tetap di splash', () {
      expect(
        resolveAppRedirect(
          authState: const AuthState(status: AuthStatus.unauthenticated),
          location: AppRoutes.splash,
          startupGate: gate,
        ),
        isNull,
      );
    });

    test('auth unauthenticated setelah gate selesai menuju /login', () {
      gate.markRevealComplete();

      expect(
        resolveAppRedirect(
          authState: const AuthState(status: AuthStatus.unauthenticated),
          location: AppRoutes.splash,
          startupGate: gate,
        ),
        AppRoutes.login,
      );
    });

    test('auth authenticated sebelum gate selesai tetap di splash', () {
      expect(
        resolveAppRedirect(
          authState: AuthState(
            status: AuthStatus.authenticated,
            user: _user(UserRole.user),
          ),
          location: AppRoutes.splash,
          startupGate: gate,
        ),
        isNull,
      );
    });

    test('auth authenticated setelah gate selesai menuju dashboard role', () {
      gate.markRevealComplete();

      expect(
        resolveAppRedirect(
          authState: AuthState(
            status: AuthStatus.authenticated,
            user: _user(UserRole.user),
          ),
          location: AppRoutes.splash,
          startupGate: gate,
        ),
        AppRoutes.dashboard,
      );

      expect(
        resolveAppRedirect(
          authState: AuthState(
            status: AuthStatus.authenticated,
            user: _user(UserRole.technician),
          ),
          location: AppRoutes.splash,
          startupGate: gate,
        ),
        AppRoutes.staffDashboard,
      );
    });

    test('authenticated session tidak pernah melewati login', () {
      gate.markRevealComplete();

      expect(
        resolveAppRedirect(
          authState: AuthState(
            status: AuthStatus.authenticated,
            user: _user(UserRole.admin),
          ),
          location: AppRoutes.login,
          startupGate: gate,
        ),
        AppRoutes.staffDashboard,
      );
    });
  });
}
