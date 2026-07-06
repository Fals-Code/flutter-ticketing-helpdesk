import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplashPage contract', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/auth/presentation/pages/splash_page.dart',
      ).readAsStringSync();
    });

    test('does not perform fallback route navigation manually', () {
      expect(source, isNot(contains('context.go')));
      expect(source, isNot(contains('context.push')));
      expect(source, isNot(contains('Navigator.of(context)')));
      expect(source, isNot(contains('appRouter.refresh()')));
      expect(source, isNot(contains('GoRouterState.of(context)')));
    });

    test('does not impose a forced splash delay before render', () {
      expect(source, isNot(contains('2500')));
      expect(
        source,
        contains('Duration(milliseconds: 1500)'),
      );
      expect(
        source,
        contains(
            'status == AuthStatus.initial || status == AuthStatus.loading'),
      );
    });

    test('startup gate is driven from splash instead of manual navigation', () {
      expect(source, contains('startupGate.markRevealComplete()'));
    });

    test('uses finite splash motion only', () {
      expect(source, isNot(contains('..repeat()')));
      expect(source, isNot(contains('with TickerProviderStateMixin')));
      expect(source, contains('with SingleTickerProviderStateMixin'));
    });
  });
}
