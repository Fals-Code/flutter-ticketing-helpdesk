import 'package:flutter_test/flutter_test.dart';
import 'package:uts/features/ticket/data/models/ticket_attachment_model.dart';
import 'package:uts/features/ticket/domain/entities/ticket_attachment_entity.dart';

void main() {
  group('TicketAttachmentModel', () {
    test('fromJson maps attachment metadata', () {
      final model = TicketAttachmentModel.fromJson({
        'id': 'att-1',
        'ticket_id': 'ticket-1',
        'storage_path': 'ticket-1/user-1/file.pdf',
        'file_name': 'file.pdf',
        'mime_type': 'application/pdf',
        'size_bytes': 4096,
        'uploaded_by': 'user-1',
        'created_at': '2026-06-01T10:00:00.000Z',
      });

      expect(model.kind, TicketAttachmentKind.document);
      expect(model.extension, 'pdf');
      expect(model.storagePath, 'ticket-1/user-1/file.pdf');
    });

    test('fromJson maps signed_url to accessUrl', () {
      final model = TicketAttachmentModel.fromJson({
        'id': 'att-2',
        'ticket_id': 'ticket-1',
        'storage_path': 'ticket-1/user-1/image.jpg',
        'file_name': 'image.jpg',
        'mime_type': 'image/jpeg',
        'size_bytes': 2048,
        'uploaded_by': 'user-1',
        'created_at': '2026-06-01T10:00:00.000Z',
        'signed_url': 'https://signed.test/image.jpg',
      });

      expect(model.accessUrl, 'https://signed.test/image.jpg');
    });

    test('toEntity preserves optional accessUrl and legacy flag', () {
      final model = TicketAttachmentModel(
        id: 'att-1',
        ticketId: 'ticket-1',
        storagePath: null,
        fileName: 'legacy.png',
        mimeType: 'image/png',
        extension: 'png',
        sizeBytes: 0,
        uploadedBy: 'user-1',
        createdAt: DateTime.utc(1970, 1, 1),
        kind: TicketAttachmentKind.image,
        accessUrl: 'https://example.test/legacy.png',
        isLegacyImage: true,
      );

      final entity = model.toEntity();

      expect(entity.accessUrl, 'https://example.test/legacy.png');
      expect(entity.isLegacyImage, isTrue);
      expect(entity.storagePath, isNull);
    });

    test('fromJson keeps nullable storagePath and accessUrl optional', () {
      final model = TicketAttachmentModel.fromJson({
        'id': 'att-2',
        'ticket_id': 'ticket-1',
        'file_name': 'file.png',
        'mime_type': 'image/png',
        'size_bytes': 1024,
        'uploaded_by': 'user-1',
        'created_at': '2026-06-01T10:00:00.000Z',
      });

      expect(model.storagePath, isNull);
      expect(model.accessUrl, isNull);
    });

    test('fromJson rejects invalid required field handling', () {
      expect(
        () => TicketAttachmentModel.fromJson({
          'id': 'att-3',
          'ticket_id': 'ticket-1',
          'mime_type': 'image/png',
          'size_bytes': 1024,
          'uploaded_by': 'user-1',
          'created_at': '2026-06-01T10:00:00.000Z',
        }),
        throwsFormatException,
      );
    });

    test('legacy image helper builds compatibility attachment', () {
      final model = TicketAttachmentModel.fromLegacyImageUrl(
        ticketId: 'ticket-legacy',
        imageUrl: 'https://example.test/images/example.jpg',
        uploadedBy: 'user-1',
      );

      expect(model.isLegacyImage, isTrue);
      expect(model.accessUrl, 'https://example.test/images/example.jpg');
      expect(model.mimeType, 'image/jpeg');
    });
  });
}
