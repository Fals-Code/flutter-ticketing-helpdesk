import 'package:flutter_test/flutter_test.dart';
import 'package:uts/main.dart';

void main() {
  testWidgets('missing configuration renders diagnostic app', (tester) async {
    await tester.pumpWidget(
      const ConfigurationErrorApp(
        isUrlMissing: true,
        isKeyMissing: true,
      ),
    );

    expect(
      find.text('Keamanan Aktif: Konfigurasi Belum Terpasang'),
      findsOneWidget,
    );
    expect(find.textContaining('Supabase URL'), findsOneWidget);
    expect(find.textContaining('Supabase Anon Key'), findsOneWidget);
    expect(find.text('Assets dan Media'), findsNothing);
  });

  testWidgets('startup failure renders a readable fallback', (tester) async {
    await tester.pumpWidget(
      const StartupErrorApp(message: 'Layanan gagal diinisialisasi.'),
    );

    expect(
      find.text('Aplikasi Tidak Dapat Diinisialisasi'),
      findsOneWidget,
    );
    expect(find.text('Layanan gagal diinisialisasi.'), findsOneWidget);
  });
}
