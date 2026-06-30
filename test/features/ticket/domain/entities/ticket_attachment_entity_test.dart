import 'package:flutter_test/flutter_test.dart';
import 'package:uts/features/ticket/domain/entities/ticket_attachment_entity.dart';

void main() {
  test('Attachment entity equality includes metadata fields', () {
    final first = TicketAttachmentEntity(
      id: 'att-1',
      ticketId: 'ticket-1',
      storagePath: 'ticket-1/user-1/file.png',
      fileName: 'file.png',
      mimeType: 'image/png',
      extension: 'png',
      sizeBytes: 2048,
      uploadedBy: 'user-1',
      createdAt: DateTime.utc(2026, 1, 1),
      kind: TicketAttachmentKind.image,
      accessUrl: 'https://example.test/file.png',
    );

    final second = TicketAttachmentEntity(
      id: 'att-1',
      ticketId: 'ticket-1',
      storagePath: 'ticket-1/user-1/file.png',
      fileName: 'file.png',
      mimeType: 'image/png',
      extension: 'png',
      sizeBytes: 2048,
      uploadedBy: 'user-1',
      createdAt: DateTime.utc(2026, 1, 1),
      kind: TicketAttachmentKind.image,
      accessUrl: 'https://example.test/file.png',
    );

    expect(first, second);
    expect(first.hasPersistedStoragePath, isTrue);
  });
}
