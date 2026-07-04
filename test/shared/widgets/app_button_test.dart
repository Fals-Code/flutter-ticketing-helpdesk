import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/shared/theme/app_theme.dart';
import 'package:uts/shared/widgets/app_button.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('primary button invokes callback when tapped', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      buildSubject(
        AppButton.primary(
          label: 'Simpan tiket',
          onPressed: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('Simpan tiket'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('loading button shows progress and ignores tap', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      buildSubject(
        AppButton.primary(
          label: 'Mengirim',
          isLoading: true,
          onPressed: () => taps++,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Mengirim'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(taps, 0);
  });
}
