import 'package:flutter_test/flutter_test.dart';
import 'package:uts/features/ticket/domain/validation/ticket_comment_validator.dart';

void main() {
  group('TicketCommentValidator', () {
    const validator = TicketCommentValidator();

    test('accepts valid trimmed message', () {
      final result = validator.validate('  Halo helpdesk  ');

      expect(result.isValid, isTrue);
      expect(result.trimmedMessage, 'Halo helpdesk');
    });

    test('rejects empty message', () {
      final result = validator.validate('   ');

      expect(result.isValid, isFalse);
      expect(result.message, 'Pesan tidak boleh kosong.');
    });

    test('rejects overly long message', () {
      final result = validator.validate('a' * 5001);

      expect(result.isValid, isFalse);
      expect(result.message, 'Pesan melebihi batas maksimum.');
    });
  });
}
