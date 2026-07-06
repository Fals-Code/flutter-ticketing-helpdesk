import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/auth/presentation/pages/login_page.dart';
import 'package:uts/shared/theme/app_theme.dart';
import 'package:uts/shared/widgets/app_password_field.dart';
import 'package:uts/shared/widgets/primary_action_button.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  late MockAuthBloc authBloc;

  EditableText passwordEditableText(WidgetTester tester) {
    return tester.widget<EditableText>(
      find.descendant(
        of: find.byType(AppPasswordField),
        matching: find.byType(EditableText),
      ),
    );
  }

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  setUp(() {
    authBloc = MockAuthBloc();
  });

  Future<void> pumpLoginPage(
    WidgetTester tester, {
    required AuthState state,
    Size size = const Size(390, 844),
    Brightness brightness = Brightness.light,
    double textScale = 1,
    EdgeInsets viewInsets = EdgeInsets.zero,
    bool settle = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => authBloc.state).thenReturn(state);
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: state,
    );

    final mediaQuery = MediaQueryData(
      size: size,
      viewInsets: viewInsets,
      textScaler: TextScaler.linear(textScale),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: mediaQuery,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const LoginPage(),
          ),
        ),
      ),
    );

    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('renders on small portrait phone without overflow', (
    tester,
  ) async {
    await pumpLoginPage(
      tester,
      state: const AuthState(status: AuthStatus.unauthenticated),
      size: const Size(320, 568),
    );

    expect(find.text('Masuk'), findsAtLeastNWidgets(1));
    expect(find.text('Belum punya akun?'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders around 360x640 without overflow', (tester) async {
    await pumpLoginPage(
      tester,
      state: const AuthState(status: AuthStatus.unauthenticated),
      size: const Size(360, 640),
    );

    expect(find.text('Email atau Username'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Lupa Kata Sandi?'), findsOneWidget);
    expect(find.text('Masuk'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('remains scrollable when viewport is cramped by keyboard', (
    tester,
  ) async {
    await pumpLoginPage(
      tester,
      state: const AuthState(status: AuthStatus.unauthenticated),
      size: const Size(360, 320),
      viewInsets: const EdgeInsets.only(bottom: 240),
    );

    final scrollable =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(find.widgetWithText(TextButton, 'Lupa Kata Sandi?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps primary fields and CTA visible at text scale 1.3', (
    tester,
  ) async {
    await pumpLoginPage(
      tester,
      state: const AuthState(status: AuthStatus.unauthenticated),
      size: const Size(360, 640),
      textScale: 1.3,
    );

    expect(find.text('Email atau Username'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Lupa Kata Sandi?'), findsOneWidget);
    expect(find.text('Masuk'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stays usable in landscape with keyboard visible', (
    tester,
  ) async {
    await pumpLoginPage(
      tester,
      state: const AuthState(status: AuthStatus.unauthenticated),
      size: const Size(640, 360),
      viewInsets: const EdgeInsets.only(bottom: 220),
    );

    expect(find.text('Masuk'), findsAtLeastNWidgets(1));
    expect(find.widgetWithText(TextButton, 'Lupa Kata Sandi?'), findsOneWidget);
    expect(find.text('Masuk'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports dark mode and larger text scale', (tester) async {
    await pumpLoginPage(
      tester,
      state: const AuthState(status: AuthStatus.unauthenticated),
      brightness: Brightness.dark,
      textScale: 1.5,
    );

    expect(find.text('Masuk'), findsAtLeastNWidgets(1));
    expect(find.text('Email atau Username'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in light and dark theme without exception', (
    tester,
  ) async {
    await pumpLoginPage(
      tester,
      state: const AuthState(status: AuthStatus.unauthenticated),
      brightness: Brightness.light,
    );
    expect(tester.takeException(), isNull);

    await pumpLoginPage(
      tester,
      state: const AuthState(status: AuthStatus.unauthenticated),
      brightness: Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows inline error banner for invalid credentials', (
    tester,
  ) async {
    await pumpLoginPage(
      tester,
      state: const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Email atau kata sandi salah',
      ),
    );

    expect(find.byKey(const ValueKey('login-error-banner')), findsOneWidget);
    expect(find.text('Email atau kata sandi salah'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggles password visibility outside loading state', (
    tester,
  ) async {
    await pumpLoginPage(
      tester,
      state: const AuthState(status: AuthStatus.unauthenticated),
    );

    expect(passwordEditableText(tester).obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(passwordEditableText(tester).obscureText, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading state disables submit and prevents duplicate tap', (
    tester,
  ) async {
    await pumpLoginPage(
      tester,
      state: const AuthState(status: AuthStatus.loading),
      settle: false,
    );

    await tester.tap(find.byType(PrimaryActionButton));
    await tester.pump();

    verifyNever(() => authBloc.add(any()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('submit is not fired twice after state turns loading', (
    tester,
  ) async {
    var currentState = const AuthState(status: AuthStatus.unauthenticated);
    final controller = StreamController<AuthState>.broadcast();
    addTearDown(controller.close);

    when(() => authBloc.state).thenAnswer((_) => currentState);
    when(() => authBloc.stream).thenAnswer((_) => controller.stream);
    when(() => authBloc.add(any())).thenAnswer((invocation) {
      currentState = const AuthState(status: AuthStatus.loading);
      controller.add(currentState);
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const LoginPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'agent@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'secret123',
    );

    await tester.tap(find.byType(PrimaryActionButton));
    await tester.pump();
    await tester.tap(find.byType(PrimaryActionButton));
    await tester.pump();

    verify(() => authBloc.add(any(that: isA<LoginSubmitted>()))).called(1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
