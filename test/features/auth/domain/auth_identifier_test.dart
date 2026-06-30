import 'package:flutter_test/flutter_test.dart';
import 'package:uts/features/auth/domain/value_objects/auth_identifier.dart';

void main() {
  group('AuthIdentifier', () {
    test('normalizes email and username', () {
      expect(AuthIdentifier.normalize('  Ahmad_01  '), 'ahmad_01');
      expect(AuthIdentifier.normalize(' USER@Example.COM '), 'user@example.com');
    });

    test('accepts valid email or username', () {
      expect(AuthIdentifier.isValid('user@example.com'), isTrue);
      expect(AuthIdentifier.isValid('ahmad_01'), isTrue);
    });

    test('rejects invalid login identifiers', () {
      expect(AuthIdentifier.isValid('ab'), isFalse);
      expect(AuthIdentifier.isValid('1invalid'), isFalse);
      expect(AuthIdentifier.isValid('invalid username'), isFalse);
    });

    test('returns clear username validation messages', () {
      expect(AuthIdentifier.validateUsername(''), isNotNull);
      expect(AuthIdentifier.validateUsername('1admin'), isNotNull);
      expect(AuthIdentifier.validateUsername('valid_user'), isNull);
    });
  });
}
