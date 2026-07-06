import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/router/app_router.dart';

void main() {
  group('AppRouter startup routes', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/core/router/app_router.dart',
      ).readAsStringSync();
    });

    test('initial location adalah /', () {
      expect(AppRoutes.splash, '/');
      expect(
        source,
        contains('initialLocation: AppRoutes.splash'),
      );
    });

    test(
      'keeps splash as no-transition and login with fade transition',
      () {
        final splashIndex = source.indexOf(
          'path: AppRoutes.splash',
        );
        final loginIndex = source.indexOf(
          'path: AppRoutes.login',
        );
        final registerIndex = source.indexOf(
          'path: AppRoutes.register',
        );

        expect(splashIndex, isNonNegative);
        expect(loginIndex, greaterThan(splashIndex));
        expect(registerIndex, greaterThan(loginIndex));

        final splashRouteSource = source.substring(
          splashIndex,
          loginIndex,
        );

        final loginRouteSource = source.substring(
          loginIndex,
          registerIndex,
        );

        final normalizedSplashRoute = splashRouteSource.replaceAll(
          RegExp(r'\s+'),
          ' ',
        );

        final normalizedLoginRoute = loginRouteSource.replaceAll(
          RegExp(r'\s+'),
          ' ',
        );

        expect(
          normalizedSplashRoute,
          contains(
            'const NoTransitionPage(child: SplashPage())',
          ),
        );

        expect(
          normalizedSplashRoute,
          isNot(contains('CustomTransitionPage')),
        );

        expect(
          normalizedLoginRoute,
          contains('const CustomTransitionPage('),
        );

        expect(
          normalizedLoginRoute,
          contains('child: LoginPage()'),
        );

        expect(
          normalizedLoginRoute,
          contains(
            'transitionsBuilder: _fadeTransition',
          ),
        );

        expect(
          normalizedLoginRoute,
          isNot(contains('NoTransitionPage')),
        );
      },
    );
  });
}
