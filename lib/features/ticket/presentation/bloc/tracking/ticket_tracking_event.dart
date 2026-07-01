import 'package:equatable/equatable.dart';

abstract class TicketTrackingEvent extends Equatable {
  const TicketTrackingEvent();

  @override
  List<Object?> get props => [];
}

class LoadTicketTrackingRequested extends TicketTrackingEvent {
  final String ticketId;

  const LoadTicketTrackingRequested(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}

class ResetTicketTrackingState extends TicketTrackingEvent {
  const ResetTicketTrackingState();
}
