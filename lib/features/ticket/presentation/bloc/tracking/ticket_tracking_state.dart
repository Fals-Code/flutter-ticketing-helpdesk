import 'package:equatable/equatable.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_tracking_item.dart';

enum TicketTrackingStatus {
  initial,
  loading,
  loaded,
  empty,
  notFound,
  unauthorized,
  failure,
}

class TicketTrackingState extends Equatable {
  final TicketTrackingStatus status;
  final TicketEntity? ticket;
  final List<TicketTrackingItem> items;
  final String? errorMessage;

  const TicketTrackingState({
    this.status = TicketTrackingStatus.initial,
    this.ticket,
    this.items = const [],
    this.errorMessage,
  });

  TicketTrackingState copyWith({
    TicketTrackingStatus? status,
    TicketEntity? ticket,
    List<TicketTrackingItem>? items,
    String? errorMessage,
    bool clearTicket = false,
    bool clearErrorMessage = false,
  }) {
    return TicketTrackingState(
      status: status ?? this.status,
      ticket: clearTicket ? null : (ticket ?? this.ticket),
      items: items ?? this.items,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        ticket,
        items,
        errorMessage,
      ];
}
