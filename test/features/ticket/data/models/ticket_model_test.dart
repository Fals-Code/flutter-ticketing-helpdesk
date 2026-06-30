import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/ticket/data/models/ticket_model.dart';

void main() {
  group('TicketModel', () {
    test('ticket with legacy images still maps successfully', () {
      final model = TicketModel.fromJson({
        'id': 'ticket-1',
        'title': 'Printer bermasalah',
        'description': 'Printer lantai 2 tidak bisa mencetak.',
        'status': 'open',
        'category': 'hardware',
        'user_id': 'user-1',
        'created_at': '2026-06-01T10:00:00.000Z',
        'images': ['https://example.test/legacy.png'],
      });

      expect(model.imageUrls, ['https://example.test/legacy.png']);
      expect(model.attachments, hasLength(1));
      expect(model.attachments.first.isLegacyImage, isTrue);
    });

    test('legacy image url does not remove attachment representation', () {
      final model = TicketModel.fromJson({
        'id': 'ticket-2',
        'title': 'Aplikasi crash',
        'description': 'Aplikasi crash saat login.',
        'status': 'open',
        'category': 'software',
        'user_id': 'user-2',
        'created_at': '2026-06-01T10:00:00.000Z',
        'images': ['https://example.test/legacy.png'],
        'ticket_attachments': [
          {
            'id': 'att-1',
            'ticket_id': 'ticket-2',
            'storage_path': 'ticket-2/user-2/file.pdf',
            'file_name': 'file.pdf',
            'mime_type': 'application/pdf',
            'size_bytes': 1024,
            'uploaded_by': 'user-2',
            'created_at': '2026-06-01T10:00:00.000Z',
          }
        ],
      });

      expect(model.attachments, hasLength(2));
      expect(model.attachments.any((item) => item.isLegacyImage), isTrue);
    });

    test('ticket without images and attachments stays valid', () {
      final model = TicketModel.fromJson({
        'id': 'ticket-3',
        'title': 'VPN gagal',
        'description': 'VPN kantor gagal tersambung.',
        'status': 'open',
        'category': 'network',
        'user_id': 'user-3',
        'created_at': '2026-06-01T10:00:00.000Z',
      });

      expect(model.attachments, isEmpty);
      expect(model.imageUrls, isEmpty);
    });

    test('reporter mapping uses joined profile when available', () {
      final model = TicketModel.fromJson({
        'id': 'ticket-4',
        'title': 'Email error',
        'description': 'Email tidak bisa dikirim.',
        'status': 'open',
        'category': 'account',
        'user_id': 'user-4',
        'created_at': '2026-06-01T10:00:00.000Z',
        'profiles': {'full_name': 'Reporter Test'},
      });

      expect(model.userName, 'Reporter Test');
    });

    test('helpdesk mapping remains optional', () {
      final model = TicketModel.fromJson({
        'id': 'ticket-5',
        'title': 'Akses WiFi',
        'description': 'Tidak bisa akses WiFi tamu.',
        'status': 'open',
        'category': 'network',
        'user_id': 'user-5',
        'created_at': '2026-06-01T10:00:00.000Z',
      });

      expect(model.assignedTo, isNull);
      expect(model.assignedToName, isNull);
    });

    test('unknown status uses project fallback convention', () {
      final model = TicketModel.fromJson({
        'id': 'ticket-6',
        'title': 'Keyboard rusak',
        'description': 'Keyboard tidak terdeteksi.',
        'status': 'unexpected_status',
        'category': 'hardware',
        'user_id': 'user-6',
        'created_at': '2026-06-01T10:00:00.000Z',
      });

      expect(model.status, TicketStatus.open);
    });

    test('priority stays optional when schema does not provide it', () {
      final model = TicketModel.fromJson({
        'id': 'ticket-7',
        'title': 'Mouse rusak',
        'description': 'Mouse bergerak sendiri.',
        'status': 'open',
        'category': 'hardware',
        'user_id': 'user-7',
        'created_at': '2026-06-01T10:00:00.000Z',
      });

      expect(model.priority, isNull);
    });

    test('timestamp mapping preserves created and updated values', () {
      final model = TicketModel.fromJson({
        'id': 'ticket-8',
        'title': 'Meeting room TV',
        'description': 'TV meeting room tidak menyala.',
        'status': 'resolved',
        'category': 'hardware',
        'user_id': 'user-8',
        'created_at': '2026-06-01T10:00:00.000Z',
        'updated_at': '2026-06-02T11:30:00.000Z',
      });

      expect(model.createdAt, DateTime.parse('2026-06-01T10:00:00.000Z'));
      expect(model.updatedAt, DateTime.parse('2026-06-02T11:30:00.000Z'));
    });
  });
}
