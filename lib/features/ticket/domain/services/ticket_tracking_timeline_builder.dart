import 'package:uts/core/constants/enums.dart';
import '../entities/ticket_entity.dart';
import '../entities/ticket_history_entity.dart';
import '../entities/ticket_tracking_item.dart';
import '../entities/ticket_tracking_view_data.dart';

class TicketTrackingTimelineBuilder {
  const TicketTrackingTimelineBuilder();

  TicketTrackingViewData build({
    required TicketEntity ticket,
    required List<TicketHistoryEntity> history,
  }) {
    final sortedHistory = [...history]..sort((a, b) {
        final cmp = a.createdAt.compareTo(b.createdAt);
        return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });

    final activityEvents = _buildActivityEvents(ticket, sortedHistory);
    final milestones = _buildMilestones(ticket, sortedHistory);

    return TicketTrackingViewData(
      lifecycleMilestones: milestones,
      activityEvents: activityEvents,
      currentStatus: ticket.status,
      isClosed: ticket.status == TicketStatus.closed,
      isReopened: ticket.status == TicketStatus.reopened,
    );
  }

  List<TicketTrackingItem> _buildActivityEvents(
    TicketEntity ticket,
    List<TicketHistoryEntity> history,
  ) {
    final events = <TicketTrackingItem>[];

    // Synthetic created event
    events.add(TicketTrackingItem(
      id: 'synthetic-created-${ticket.id}',
      ticketId: ticket.id,
      title: 'Tiket dibuat',
      description: 'Tiket berhasil dibuat.',
      actorName: ticket.userName,
      occurredAt: ticket.createdAt,
      type: 'created',
    ));

    // Map history to items
    final historyItems = history.map(TicketTrackingItem.fromHistory).toList();

    // Deduplicate and add
    for (final item in historyItems) {
      if (item.title == 'Tiket Dibuat' &&
          (item.occurredAt.difference(ticket.createdAt).inSeconds.abs() < 5)) {
        continue;
      }
      events.add(item);
    }

    events.sort((a, b) {
      final timeComparison = a.occurredAt.compareTo(b.occurredAt);

      if (timeComparison != 0) {
        return timeComparison;
      }

      return a.id.compareTo(b.id);
    });

    // Aktivitas terbaru berada pada elemen terakhir karena timeline
// disusun secara kronologis dari aktivitas terlama ke terbaru.
    if (events.isNotEmpty) {
      final lastIndex = events.length - 1;
      final latestEvent = events[lastIndex];

      events[lastIndex] = TicketTrackingItem(
        id: latestEvent.id,
        ticketId: latestEvent.ticketId,
        title: latestEvent.title,
        description: latestEvent.description,
        actorName: latestEvent.actorName,
        occurredAt: latestEvent.occurredAt,
        oldStatus: latestEvent.oldStatus,
        newStatus: latestEvent.newStatus,
        type: latestEvent.type,
        isCompleted: true,
        isCurrent: true,
      );
    }

    return events;
  }

  List<TicketLifecycleMilestone> _buildMilestones(
    TicketEntity ticket,
    List<TicketHistoryEntity> history,
  ) {
    DateTime? assignedAt;
    DateTime? inProgressAt;
    DateTime? resolvedAt;
    DateTime? closedAt;

    final hasAssignmentEvidence = ticket.assignedTo != null ||
        history.any((h) =>
            h.activityType == 'assignment' ||
            (h.metadata != null && h.metadata!.containsKey('assigned_to')));

    if (hasAssignmentEvidence) {
      assignedAt = history
          .where((h) =>
              h.activityType == 'assignment' ||
              (h.metadata != null && h.metadata!.containsKey('assigned_to')))
          .firstOrNull
          ?.createdAt;
      // If we have assignedTo but no history, we can't be sure about timestamp,
      // so we use null or ticket.createdAt if it's the only info.
      // But the rules say don't mark completed without evidence.
    }

    inProgressAt = history
        .where((h) => h.newStatus?.toLowerCase() == 'in_progress')
        .firstOrNull
        ?.createdAt;

    resolvedAt = history
        .where((h) => h.newStatus?.toLowerCase() == 'resolved')
        .firstOrNull
        ?.createdAt;

    closedAt = history
        .where((h) => h.newStatus?.toLowerCase() == 'closed')
        .firstOrNull
        ?.createdAt;

    final currentStatus = ticket.status;

    return [
      TicketLifecycleMilestone(
        title: 'Dibuat',
        state: MilestoneState.completed,
        timestamp: ticket.createdAt,
      ),
      _determineMilestone(
        'Ditugaskan',
        assignedAt,
        currentStatus,
        [TicketStatus.inProgress, TicketStatus.resolved, TicketStatus.closed]
            .contains(currentStatus),
        hasAssignmentEvidence,
      ),
      _determineMilestone(
        'Diproses',
        inProgressAt,
        currentStatus,
        [TicketStatus.resolved, TicketStatus.closed].contains(currentStatus),
        currentStatus == TicketStatus.inProgress,
      ),
      _determineMilestone(
        'Selesai',
        resolvedAt,
        currentStatus,
        currentStatus == TicketStatus.closed,
        currentStatus == TicketStatus.resolved,
      ),
      _determineMilestone(
        'Ditutup',
        closedAt,
        currentStatus,
        false, // No state after closed
        currentStatus == TicketStatus.closed,
      ),
    ];
  }

  TicketLifecycleMilestone _determineMilestone(
    String title,
    DateTime? evidenceTimestamp,
    TicketStatus currentStatus,
    bool isPassed,
    bool isCurrent,
  ) {
    if (isCurrent) {
      return TicketLifecycleMilestone(
        title: title,
        state: MilestoneState.current,
        timestamp: evidenceTimestamp,
      );
    }
    if (isPassed || evidenceTimestamp != null) {
      return TicketLifecycleMilestone(
        title: title,
        state: MilestoneState.completed,
        timestamp: evidenceTimestamp,
      );
    }
    return TicketLifecycleMilestone(
      title: title,
      state: MilestoneState.pending,
    );
  }
}
