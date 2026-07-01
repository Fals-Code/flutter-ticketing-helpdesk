import 'package:equatable/equatable.dart';

import '../../../../core/constants/enums.dart';

class TicketQuery extends Equatable {
  static const int defaultLimit = 10;

  final String? search;
  final TicketStatus? status;
  final String? category;
  final TicketPriority? priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int limit;
  final int offset;

  const TicketQuery._({
    required this.search,
    required this.status,
    required this.category,
    required this.priority,
    required this.startDate,
    required this.endDate,
    required this.page,
    required this.limit,
    required this.offset,
  });

  factory TicketQuery({
    String? search,
    TicketStatus? status,
    String? category,
    TicketPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    int page = 0,
    int limit = defaultLimit,
    int? offset,
  }) {
    final normalizedSearch = search?.trim();
    final normalizedCategory = category?.trim();
    final safePage = page < 0 ? 0 : page;
    final safeLimit = limit <= 0 ? defaultLimit : limit;
    final safeOffset =
        offset == null || offset < 0 ? safePage * safeLimit : offset;

    return TicketQuery._(
      search: normalizedSearch == null || normalizedSearch.isEmpty
          ? null
          : normalizedSearch,
      status: status,
      category: normalizedCategory == null || normalizedCategory.isEmpty
          ? null
          : normalizedCategory,
      priority: priority,
      startDate: startDate,
      endDate: endDate,
      page: safePage,
      limit: safeLimit,
      offset: safeOffset,
    );
  }

  TicketQuery copyWith({
    String? search,
    TicketStatus? status,
    String? category,
    TicketPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
    int? offset,
    bool clearSearch = false,
    bool clearStatus = false,
    bool clearCategory = false,
    bool clearPriority = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return TicketQuery(
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
      category: clearCategory ? null : (category ?? this.category),
      priority: clearPriority ? null : (priority ?? this.priority),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      page: page ?? this.page,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  List<Object?> get props => [
        search,
        status,
        category,
        priority,
        startDate,
        endDate,
        page,
        limit,
        offset,
      ];
}
