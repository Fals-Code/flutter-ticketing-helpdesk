import 'package:equatable/equatable.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_state.dart';

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
  const FetchAllTicketsRequested({this.page = 0, this.limit = 10, this.assignedToId});
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

class CreateTicketRequested extends TicketListEvent {
  final String userId;
  final String title;
  final String description;
  final String category;
  final String priority;
  final List<String> imagePaths;

  const CreateTicketRequested({
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.imagePaths,
  });

  @override
  List<Object?> get props => [userId, title, description, category, priority, imagePaths];
}

class StartTicketListSubscription extends TicketListEvent {
  final String? userId;
  final String? assignedToId;
  const StartTicketListSubscription({this.userId, this.assignedToId});
  @override
  List<Object?> get props => [userId, assignedToId];
}

class ResetTicketListState extends TicketListEvent {}
