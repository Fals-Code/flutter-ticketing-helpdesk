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

    test('success action opens created ticket detail without context.go', () {
      final lihatTiketIndex = source.indexOf("label: 'Lihat Tiket'");
      expect(lihatTiketIndex, isNonNegative);

      final successActionSource = source.substring(
        lihatTiketIndex,
        source.indexOf("label: 'Kembali ke Beranda'", lihatTiketIndex),
      );

      expect(source, contains('final ticketId = state.ticket?.id.trim();'));
      expect(successActionSource, contains('pushReplacementNamed'));
      expect(successActionSource, contains("'ticket-detail'"));
      expect(successActionSource, isNot(contains('context.go')));
    });
  });
}
