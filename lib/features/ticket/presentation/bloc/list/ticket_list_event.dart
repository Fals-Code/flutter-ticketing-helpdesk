import 'package:equatable/equatable.dart';
import 'package:uts/core/constants/enums.dart';

abstract class TicketListEvent extends Equatable {
  const TicketListEvent();
  @override
  List<Object?> get props => [];
}

class FetchTicketsRequested extends TicketListEvent {
  final int page;
  final int limit;
  const FetchTicketsRequested({this.page = 0, this.limit = 10});
  @override
  List<Object?> get props => [page, limit];
}

class FetchAllTicketsRequested extends TicketListEvent {
  final int page;
  final int limit;
  final String? assignedToId;
  const FetchAllTicketsRequested(
      {this.page = 0, this.limit = 10, this.assignedToId});
  @override
  List<Object?> get props => [page, limit, assignedToId];
}

class SearchTicketsRequested extends TicketListEvent {
  final String query;
  const SearchTicketsRequested(this.query);
  @override
  List<Object?> get props => [query];
}

class FilterStatusChanged extends TicketListEvent {
  final TicketStatusFilter filter;
  const FilterStatusChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

class FilterCategoryChanged extends TicketListEvent {
  final String? category;
  const FilterCategoryChanged(this.category);
  @override
  List<Object?> get props => [category];
}

class FilterDateRangeChanged extends TicketListEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  const FilterDateRangeChanged(this.startDate, this.endDate);
  @override
  List<Object?> get props => [startDate, endDate];
}

class CreateTicketRequested extends TicketListEvent {
  final String userId;
  final String title;
  final String description;
  final String category;
  final List<String> imagePaths;

  const CreateTicketRequested({
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.imagePaths,
  });

  @override
  List<Object?> get props => [userId, title, description, category, imagePaths];
}

class StartTicketListSubscription extends TicketListEvent {
  final String? userId;
  final String? assignedToId;
  final bool isStaff;

  const StartTicketListSubscription({
    this.userId,
    this.assignedToId,
    this.isStaff = false,
  });

  @override
  List<Object?> get props => [userId, assignedToId, isStaff];
}

class ResetTicketListState extends TicketListEvent {}
