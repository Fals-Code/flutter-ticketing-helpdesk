import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/auth/domain/entities/user_entity.dart';

/// Keputusan redirect autentikasi dan RBAC yang bebas dari Flutter context.
///
/// Backend RLS tetap menjadi batas keamanan utama. Guard ini mencegah user
/// tersesat ke layar yang tidak sesuai role dan mengamankan deep link.
abstract final class AuthRouteGuard {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String resetPassword = '/reset-password';
  static const String changePassword = '/change-password';
  static const String dashboard = '/dashboard';
  static const String staffDashboard = '/staff-dashboard';
  static const String ticketManagement = '/ticket-management';
  static const String adminReports = '/admin-reports';
  static const String adminSettings = '/admin-settings';
  static const String userManagement = '/user-management';

  static const Set<String> _publicAuthRoutes = {
    login,
    register,
    resetPassword,
  };

  static const Set<String> _staffRoutes = {
    staffDashboard,
    ticketManagement,
  };

  static const Set<String> _adminOnlyRoutes = {
    adminReports,
    adminSettings,
    userManagement,
  };

  static String? redirect({
    required AuthStatus status,
    required AuthUser user,
    required String location,
    String? from,
  }) {
    final isPublicAuthRoute = _publicAuthRoutes.contains(location);
    final isSplash = location == splash;

    if (status == AuthStatus.initial) {
      return isSplash ? null : splash;
    }

    if (status == AuthStatus.loading) {
      if (user.isNotEmpty || isPublicAuthRoute) {
        return null;
      }
      return isSplash ? null : splash;
    }

    if (status == AuthStatus.passwordRecovery) {
      return location == changePassword ? null : changePassword;
    }

    final hasAuthenticatedUser = user.isNotEmpty &&
        (status == AuthStatus.authenticated ||
            status == AuthStatus.success ||
            status == AuthStatus.error);

    if (hasAuthenticatedUser) {
      final home = homeFor(user.role);
      if (isPublicAuthRoute || isSplash) {
        final safeDestination = safeFrom(from, user.role);
        return safeDestination ?? home;
      }
      if (!canAccess(user.role, location)) {
        return home;
      }
      return null;
    }

    if (status == AuthStatus.unauthenticated ||
        status == AuthStatus.sessionExpired ||
        status == AuthStatus.error ||
        status == AuthStatus.success) {
      if (isPublicAuthRoute) {
        return null;
      }
      if (isSplash) {
        return login;
      }
      if (status == AuthStatus.success && location == changePassword) {
        return null;
      }
      return loginWithFrom(location);
    }

    return null;
  }

  static bool canAccess(UserRole role, String location) {
    if (role == UserRole.admin) {
      return true;
    }
    if (role == UserRole.technician) {
      return !_adminOnlyRoutes.contains(location);
    }
    return !_staffRoutes.contains(location) &&
        !_adminOnlyRoutes.contains(location);
  }

  static String homeFor(UserRole role) =>
      role == UserRole.user ? dashboard : staffDashboard;

  static String? safeFrom(String? value, UserRole role) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.isAbsolute && !value.startsWith('/') ||
        uri.hasScheme ||
        uri.hasAuthority ||
        value.startsWith('//')) {
      return null;
    }
    final path = uri.path;
    if (path.isEmpty ||
        path == splash ||
        _publicAuthRoutes.contains(path) ||
        path == changePassword ||
        !canAccess(role, path)) {
      return null;
    }
    return value;
  }

  static String loginWithFrom(String location) {
    return Uri(
      path: login,
      queryParameters: <String, String>{'from': location},
    ).toString();
  }
}
