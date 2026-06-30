import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/router/auth_route_guard.dart';

void main() {
  group('Create ticket access matrix', () {
    test('User can see or open create action', () {
      expect(AuthRouteGuard.canCreateTicket(UserRole.user), isTrue);
    });

    test('Helpdesk can see or open create action', () {
      expect(AuthRouteGuard.canCreateTicket(UserRole.technician), isTrue);
    });

    test('Admin can see or open create action', () {
      expect(AuthRouteGuard.canCreateTicket(UserRole.admin), isTrue);
    });
  });
}
