import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uts/features/ticket/data/datasources/ticket_attachment_storage_data_source.dart';
import 'package:uts/features/ticket/domain/entities/local_attachment_candidate.dart';

void main() {
  group('SupabaseTicketAttachmentStorageDataSource', () {
    final dataSource = SupabaseTicketAttachmentStorageDataSource(
      SupabaseClient('https://example.supabase.co', 'anon-key'),
    );

    const candidate = LocalAttachmentCandidate(
      localPath: 'C:/tmp/evidence.pdf',
      fileName: 'Evidence File (Final).pdf',
      mimeType: 'application/pdf',
      extension: 'pdf',
      sizeBytes: 2048,
      source: LocalAttachmentSource.document,
    );

    test('builds storage path using ticket, user, and attachment namespace',
        () {
      final path = dataSource.buildStoragePath(
        ticketId: '20000000-0000-4000-8000-000000000001',
        userId: '10000000-0000-4000-8000-000000000001',
        attachmentId: '30000000-0000-4000-8000-000000000001',
        candidate: candidate,
      );

      expect(
        path,
        startsWith(
          '20000000-0000-4000-8000-000000000001/'
          '10000000-0000-4000-8000-000000000001/'
          '30000000-0000-4000-8000-000000000001-',
        ),
      );
      expect(path, endsWith('.pdf'));
      expect(path, isNot(contains(' ')));
      expect(path, isNot(startsWith('http')));
    });

    test('uploaded attachment manifest stores storagePath, not access URL', () {
      const uploaded = UploadedTicketAttachment(
        id: 'attachment-1',
        storagePath: 'ticket-id/user-id/attachment-id-evidence.pdf',
        fileName: 'attachment-id-evidence.pdf',
        mimeType: 'application/pdf',
        extension: 'pdf',
        sizeBytes: 2048,
        source: LocalAttachmentSource.document,
      );

      final json = uploaded.toManifestJson();

      expect(
          json['storage_path'], 'ticket-id/user-id/attachment-id-evidence.pdf');
      expect(json, isNot(contains('public_url')));
      expect(json, isNot(contains('signed_url')));
      expect(json, isNot(contains('access_url')));
    });
  });
}
