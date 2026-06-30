import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/router/app_router.dart';

void main() {
  test('tracking route path is stable', () {
    expect(AppRoutes.ticketTracking, '/tickets/:id/tracking');
  });
}
