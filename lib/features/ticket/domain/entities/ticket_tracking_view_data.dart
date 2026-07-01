import 'package:equatable/equatable.dart';
import 'package:uts/core/constants/enums.dart';
import 'ticket_tracking_item.dart';

enum MilestoneState { completed, current, pending, interrupted }

class TicketLifecycleMilestone extends Equatable {
  final String title;
  final MilestoneState state;
  final DateTime? timestamp;

  const TicketLifecycleMilestone({
    required this.title,
    required this.state,
    this.timestamp,
  });

  @override
  List<Object?> get props => [title, state, timestamp];
}

class TicketTrackingViewData extends Equatable {
  final List<TicketLifecycleMilestone> lifecycleMilestones;
  final List<TicketTrackingItem> activityEvents;
  final TicketStatus currentStatus;
  final bool isClosed;
  final bool isReopened;

  const TicketTrackingViewData({
    required this.lifecycleMilestones,
    required this.activityEvents,
    required this.currentStatus,
    required this.isClosed,
    required this.isReopened,
  });

  @override
  List<Object?> get props => [
        lifecycleMilestones,
        activityEvents,
        currentStatus,
        isClosed,
        isReopened,
      ];
}
