import 'package:equatable/equatable.dart';

class PaginatedResult<T> extends Equatable {
  final List<T> items;
  final bool hasMore;
  final int? nextPage;
  final int? nextOffset;
  final int? total;

  const PaginatedResult({
    required this.items,
    required this.hasMore,
    this.nextPage,
    this.nextOffset,
    this.total,
  });

  const PaginatedResult.empty()
      : items = const [],
        hasMore = false,
        nextPage = null,
        nextOffset = null,
        total = 0;

  @override
  List<Object?> get props => [
        items,
        hasMore,
        nextPage,
        nextOffset,
        total,
      ];
}
