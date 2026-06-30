import 'package:flutter_test/flutter_test.dart';
import 'package:uts/features/ticket/domain/entities/create_ticket_params.dart';
import 'package:uts/features/ticket/domain/entities/local_attachment_candidate.dart';

void main() {
  group('CreateTicketParams', () {
    test('trims title and description', () {
      const params = CreateTicketParams(
        title: '  Printer error  ',
        description: '  Printer lantai 2 tidak dapat mencetak dokumen.  ',
        category: ' hardware ',
      );

      expect(params.trimmedTitle, 'Printer error');
      expect(
        params.trimmedDescription,
        'Printer lantai 2 tidak dapat mencetak dokumen.',
      );
      expect(params.trimmedCategory, 'hardware');
    });

    test('does not expose reporter id, status, role, or assignment fields', () {
      final params = const CreateTicketParams(
        title: 'Printer error',
        description: 'Printer lantai 2 tidak dapat mencetak dokumen.',
        category: 'hardware',
      ).toString();

      expect(params, isNot(contains('userId')));
      expect(params, isNot(contains('status')));
      expect(params, isNot(contains('role')));
      expect(params, isNot(contains('assigned')));
    });

    test('keeps local attachment candidates as pre-upload input', () {
      const attachment = LocalAttachmentCandidate(
        localPath: 'C:/tmp/evidence.pdf',
        fileName: 'evidence.pdf',
        mimeType: 'application/pdf',
        extension: 'pdf',
        sizeBytes: 1024,
        source: LocalAttachmentSource.document,
      );

      const params = CreateTicketParams(
        title: 'Aplikasi error',
        description: 'Aplikasi error saat membuka menu laporan.',
        category: 'software',
        attachments: [attachment],
      );

      expect(params.attachments, [attachment]);
    });
  });
}
