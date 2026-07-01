import 'package:flutter_test/flutter_test.dart';
import 'package:uts/features/ticket/domain/value_objects/paginated_result.dart';

void main() {
  group('PaginatedResult', () {
    test('hasMore state is preserved', () {
      const result = PaginatedResult<int>(
        items: [1, 2, 3],
        hasMore: true,
        nextPage: 2,
      );

      expect(result.hasMore, isTrue);
      expect(result.nextPage, 2);
    });

    test('empty paginated result is supported', () {
      const result = PaginatedResult<int>.empty();

      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);
      expect(result.total, 0);
    });
  });
}
