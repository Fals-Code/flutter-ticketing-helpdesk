import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateTicketPage contract', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/ticket/presentation/pages/create_ticket_page.dart',
      ).readAsStringSync();
    });

    test('offers camera, gallery, and document attachment sources', () {
      expect(source, contains('Kamera'));
      expect(source, contains('Galeri'));
      expect(source, contains('Dokumen PDF'));
    });

    test('does not call Supabase directly from presentation', () {
      expect(source, isNot(contains('Supabase.instance')));
      expect(source, isNot(contains('.storage.from')));
    });

    test('submits through TicketCreateBloc', () {
      expect(source, contains('TicketCreateBloc'));
      expect(source, contains('SubmitTicketCreateRequested'));
    });
  });
}
