import 'package:equatable/equatable.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_tracking_view_data.dart';

enum TicketTrackingStatus {
  initial,
  loading,
  loaded,
  notFound,
  unauthorized,
  failure,
}

class TicketTrackingState extends Equatable {
  final TicketTrackingStatus status;
  final TicketEntity? ticket;
  final TicketTrackingViewData? viewData;
  final String? errorMessage;

  const TicketTrackingState({
    this.status = TicketTrackingStatus.initial,
    this.ticket,
    this.viewData,
    this.errorMessage,
  });

  TicketTrackingState copyWith({
    TicketTrackingStatus? status,
    TicketEntity? ticket,
    TicketTrackingViewData? viewData,
    String? errorMessage,
    bool clearTicket = false,
    bool clearErrorMessage = false,
    bool clearViewData = false,
  }) {
    return TicketTrackingState(
      status: status ?? this.status,
      ticket: clearTicket ? null : (ticket ?? this.ticket),
      viewData: clearViewData ? null : (viewData ?? this.viewData),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        ticket,
        viewData,
        errorMessage,
      ];
}
