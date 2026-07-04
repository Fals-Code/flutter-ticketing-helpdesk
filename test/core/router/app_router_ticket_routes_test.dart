import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRouter ticket route hierarchy', () {
    late String source;

    setUpAll(() {
      source = File('lib/core/router/app_router.dart').readAsStringSync();
    });

    test('keeps create and detail as top-level siblings of ticket list', () {
      final listRouteIndex = source.indexOf('path: AppRoutes.tickets');
      final createRouteIndex = source.indexOf('path: AppRoutes.createTicket');
      final trackingRouteIndex =
          source.indexOf('path: AppRoutes.ticketTracking');
      final detailRouteIndex = source.indexOf('path: AppRoutes.ticketDetail');

      expect(listRouteIndex, isNonNegative);
      expect(createRouteIndex, greaterThan(listRouteIndex));
      expect(trackingRouteIndex, greaterThan(createRouteIndex));
      expect(detailRouteIndex, greaterThan(trackingRouteIndex));

      final listRouteSource = source.substring(
        listRouteIndex,
        createRouteIndex,
      );
      expect(listRouteSource, contains('child: TicketListPage()'));
      expect(listRouteSource, isNot(contains('routes: [')));
    });

    test('defines create before dynamic detail route', () {
      expect(
        source.indexOf('path: AppRoutes.createTicket'),
        lessThan(source.indexOf('path: AppRoutes.ticketDetail')),
      );
    });
  });
}
