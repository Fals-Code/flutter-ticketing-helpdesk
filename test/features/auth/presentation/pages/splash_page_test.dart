import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/constants/app_strings.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/router/startup_gate.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/auth/presentation/pages/splash_page.dart';
import 'package:uts/shared/theme/app_theme.dart';
import 'package:uts/shared/widgets/ticket_q_mark.dart';

// mocktail tersedia melalui bloc_test pada baseline proyek.
// ignore: depend_on_referenced_packages
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  late MockAuthBloc authBloc;

  double opacityOf(WidgetTester tester, Key key) {
    return tester.widget<Opacity>(find.byKey(key)).opacity;
  }

  double translateYOf(WidgetTester tester, Key key) {
    return tester.widget<Transform>(find.byKey(key)).transform.storage[13];
  }

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  setUp(() {
    authBloc = MockAuthBloc();
    startupGate.reset();
  });

  Widget buildSubject({
    required AuthState state,
    bool disableAnimations = false,
    Size size = const Size(390, 844),
    Brightness brightness = Brightness.light,
    VoidCallback? onMinimumRevealComplete,
    Duration minimumRevealDuration = const Duration(milliseconds: 1500),
    Duration reducedMotionRevealDuration = const Duration(milliseconds: 150),
  }) {
    when(() => authBloc.state).thenReturn(state);
    whenListen(authBloc, const Stream<AuthState>.empty(), initialState: state);

    return MediaQuery(
      data: MediaQueryData(size: size, disableAnimations: disableAnimations),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode:
            brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: SplashPage(
            onMinimumRevealComplete: onMinimumRevealComplete,
            minimumRevealDuration: minimumRevealDuration,
            reducedMotionRevealDuration: reducedMotionRevealDuration,
          ),
        ),
      ),
    );
  }

  group('SplashPage', () {
    testWidgets('does not overflow on a small viewport', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 480);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildSubject(
          state: const AuthState(status: AuthStatus.loading),
          size: const Size(320, 480),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text(AppStrings.appName), findsAtLeastNWidgets(1));
      expect(find.text('Menyiapkan sesi aman Anda...'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in light theme without exception', (tester) async {
      await tester.pumpWidget(
        buildSubject(state: const AuthState(status: AuthStatus.initial)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark theme without exception', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          state: const AuthState(status: AuthStatus.initial),
          brightness: Brightness.dark,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders branding immediately without forced wait', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(state: const AuthState(status: AuthStatus.initial)),
      );

      expect(find.text(AppStrings.appName), findsAtLeastNWidgets(1));
      expect(find.text(AppStrings.appTagline), findsOneWidget);
      expect(find.text('Menyiapkan sesi aman Anda...'), findsNothing);

      await tester.pump(const Duration(milliseconds: 799));
      expect(find.text('Menyiapkan sesi aman Anda...'), findsNothing);

      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('Menyiapkan sesi aman Anda...'), findsOneWidget);
    });

    testWidgets('shows startup progress with semantics on slow startup', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(state: const AuthState(status: AuthStatus.loading)),
      );

      await tester.pump(const Duration(milliseconds: 800));

      final progressSemantics = tester.widget<Semantics>(
        find.byKey(const ValueKey('startup-progress')),
      );
      expect(
        progressSemantics.properties.label,
        'Status startup: Menyiapkan sesi aman Anda',
      );
      expect(find.byKey(const ValueKey('startup-progress')), findsOneWidget);
      expect(find.text('Menyiapkan sesi aman Anda...'), findsOneWidget);
    });

    testWidgets('respects reduced motion by skipping entrance animation', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          state: const AuthState(status: AuthStatus.initial),
          disableAnimations: true,
        ),
      );

      final fade = tester.widget<FadeTransition>(
        find.byKey(const ValueKey('splash-fade')),
      );
      final scale = tester.widget<ScaleTransition>(
        find.byKey(const ValueKey('splash-scale')),
      );

      expect(fade.opacity.value, 1);
      expect(scale.scale.value, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 900));
    });

    testWidgets(
      'starts splash sequence after first frame with 1500 ms duration',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(state: const AuthState(status: AuthStatus.initial)),
        );
        await tester.pump();

        final dynamic state = tester.state(find.byType(SplashPage));
        final initialScale = tester
            .widget<ScaleTransition>(find.byKey(const ValueKey('splash-scale')))
            .scale
            .value;

        expect(
          state.debugControllerDuration,
          const Duration(milliseconds: 1500),
        );
        expect(state.debugStartedAfterFirstFrame, isTrue);
        expect(initialScale, closeTo(0.96, 0.02));

        await tester.pump(const Duration(milliseconds: 120));

        final advancedScale = tester
            .widget<ScaleTransition>(find.byKey(const ValueKey('splash-scale')))
            .scale
            .value;

        expect(advancedScale, greaterThan(initialScale));
      },
    );

    testWidgets('hero stage changes within first 450 ms', (tester) async {
      await tester.pumpWidget(
        buildSubject(state: const AuthState(status: AuthStatus.initial)),
      );
      await tester.pump();

      final initialHeroOpacity = opacityOf(
        tester,
        const ValueKey('splash-hero'),
      );

      await tester.pump(const Duration(milliseconds: 450));

      expect(
        opacityOf(tester, const ValueKey('splash-hero')),
        lessThan(initialHeroOpacity),
      );
    });

    testWidgets('hero collapse is visible by 900 ms', (tester) async {
      await tester.pumpWidget(
        buildSubject(state: const AuthState(status: AuthStatus.initial)),
      );
      await tester.pump();

      final initialHeroSize = tester.getSize(
        find.byKey(const ValueKey('splash-hero-container')),
      );

      await tester.pump(const Duration(milliseconds: 900));

      final collapsedHeroSize = tester.getSize(
        find.byKey(const ValueKey('splash-hero-container')),
      );
      expect(collapsedHeroSize.width, lessThan(initialHeroSize.width));
      expect(collapsedHeroSize.height, lessThan(initialHeroSize.height));
    });

    testWidgets('compact brand is visible by 1250 ms', (tester) async {
      await tester.pumpWidget(
        buildSubject(state: const AuthState(status: AuthStatus.initial)),
      );
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 1250));

      expect(
        opacityOf(tester, const ValueKey('splash-compact')),
        greaterThan(0.9),
      );
      expect(
        translateYOf(tester, const ValueKey('splash-brand-stage')),
        lessThan(2),
      );
    });

    testWidgets('tagline is visible and gate completes at 1500 ms', (
      tester,
    ) async {
      var calls = 0;

      await tester.pumpWidget(
        buildSubject(
          state: const AuthState(status: AuthStatus.initial),
          onMinimumRevealComplete: () => calls++,
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 1499));

      expect(opacityOf(tester, const ValueKey('splash-tagline')), lessThan(1));
      expect(startupGate.minimumRevealComplete, isFalse);
      expect(calls, 0);

      await tester.pump(const Duration(milliseconds: 1));

      expect(opacityOf(tester, const ValueKey('splash-tagline')), 1);
      expect(startupGate.minimumRevealComplete, isTrue);
      expect(calls, 1);
    });

    testWidgets('startup gate does not complete before the full sequence', (
      tester,
    ) async {
      var calls = 0;

      await tester.pumpWidget(
        buildSubject(
          state: const AuthState(status: AuthStatus.unauthenticated),
          onMinimumRevealComplete: () => calls++,
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 900));

      expect(startupGate.minimumRevealComplete, isFalse);
      expect(calls, 0);
    });

    testWidgets('markRevealComplete hanya terpanggil sekali', (tester) async {
      var calls = 0;

      await tester.pumpWidget(
        buildSubject(
          state: const AuthState(status: AuthStatus.initial),
          onMinimumRevealComplete: () => calls++,
          minimumRevealDuration: const Duration(milliseconds: 150),
        ),
      );

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 400));

      expect(calls, 1);
      expect(startupGate.minimumRevealComplete, isTrue);
    });

    testWidgets('delayed progress callback stays safe after dispose', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(state: const AuthState(status: AuthStatus.initial)),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 900));

      expect(tester.takeException(), isNull);
    });

    testWidgets('dispose before minimum reveal timer selesai tidak exception', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          state: const AuthState(status: AuthStatus.initial),
          minimumRevealDuration: const Duration(milliseconds: 300),
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 350));

      expect(tester.takeException(), isNull);
      expect(startupGate.minimumRevealComplete, isFalse);
    });

    testWidgets('reduced motion tidak menyebabkan startup gate menggantung', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          state: const AuthState(status: AuthStatus.initial),
          disableAnimations: true,
        ),
      );

      await tester.pump(const Duration(milliseconds: 151));

      expect(startupGate.minimumRevealComplete, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not keep scheduling frames after entrance completes', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          state: const AuthState(status: AuthStatus.unauthenticated),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TicketQMark exposes the expected semantic label', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TicketQMark())),
      );

      expect(find.bySemanticsLabel('Logo TICKET-Q'), findsOneWidget);
    });
  });
}
