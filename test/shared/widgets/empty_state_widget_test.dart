import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/shared/theme/app_theme.dart';
import 'package:uts/shared/widgets/empty_state_widget.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  testWidgets('offline factory renders message and action', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      buildSubject(
        EmptyStateWidget.offline(
          onAction: () => retries++,
        ),
      ),
    );

    expect(find.text('Anda sedang offline'), findsOneWidget);
    expect(find.text('Periksa koneksi lalu coba lagi.'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(retries, 1);
  });

  testWidgets('error factory uses error illustration and retry label', (
    tester,
  ) async {
    var reloads = 0;

    await tester.pumpWidget(
      buildSubject(
        EmptyStateWidget.error(
          onAction: () => reloads++,
        ),
      ),
    );

    expect(find.text('Terjadi kendala'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text('Muat ulang'), findsOneWidget);

    await tester.tap(find.text('Muat ulang'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(reloads, 1);
  });
}
