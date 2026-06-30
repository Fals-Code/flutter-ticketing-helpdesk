import 'package:flutter_test/flutter_test.dart';
import 'package:uts/app/startup_status_apps.dart';

void main() {
  group('Application bootstrap', () {
    testWidgets('shows a safe configuration error when build values are absent',
        (tester) async {
      await tester.pumpWidget(
        const ConfigurationErrorApp(
          isUrlMissing: true,
          isKeyMissing: true,
        ),
      );

      expect(find.text('Konfigurasi Belum Terpasang'), findsOneWidget);
      expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
      expect(find.textContaining('SUPABASE_ANON_KEY'), findsOneWidget);
      expect(find.text('Assets dan Media'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows a controlled page when service initialization fails',
        (tester) async {
      await tester.pumpWidget(
        const StartupErrorApp(message: 'service initialization failed'),
      );

      expect(find.text('Aplikasi Gagal Dimulai'), findsOneWidget);
      expect(find.text('service initialization failed'), findsOneWidget);
      expect(find.text('Assets dan Media'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
