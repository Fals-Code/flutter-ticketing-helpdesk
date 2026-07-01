import 'package:flutter_test/flutter_test.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_history_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_tracking_view_data.dart';
import 'package:uts/features/ticket/domain/services/ticket_tracking_timeline_builder.dart';

void main() {
  late TicketTrackingTimelineBuilder builder;

  final now = DateTime.now();

  final tTicket = TicketEntity(
    id: 'ticket-1',
    title: 'Test Ticket',
    description: 'Description',
    status: TicketStatus.open,
    category: 'Bug',
    createdAt: now.subtract(const Duration(hours: 2)),
    userId: 'user-1',
    userName: 'Reporter Name',
  );

  setUp(() {
    builder = const TicketTrackingTimelineBuilder();
  });

  test(
    'Open ticket tanpa history menghasilkan created milestone dan activity',
    () {
      final result = builder.build(
        ticket: tTicket,
        history: const [],
      );

      expect(result.lifecycleMilestones[0].title, 'Dibuat');
      expect(
        result.lifecycleMilestones[0].state,
        MilestoneState.completed,
      );

      expect(result.activityEvents, hasLength(1));
      expect(result.activityEvents.first.type, 'created');
      expect(result.activityEvents.first.isCurrent, isTrue);
    },
  );

  test('Created memakai ticket.createdAt', () {
    final result = builder.build(
      ticket: tTicket,
      history: const [],
    );

    expect(
      result.activityEvents.first.occurredAt,
      tTicket.createdAt,
    );
  });

  test('Reporter dipakai sebagai actor bila tersedia', () {
    final result = builder.build(
      ticket: tTicket,
      history: const [],
    );

    expect(
      result.activityEvents.first.actorName,
      tTicket.userName,
    );
  });

  test('Assigned milestone memerlukan evidence', () {
    final resultWithoutAssignment = builder.build(
      ticket: tTicket,
      history: const [],
    );

    expect(
      resultWithoutAssignment.lifecycleMilestones[1].state,
      MilestoneState.pending,
    );

    final assignedTicket = TicketEntity(
      id: 'ticket-1',
      title: 'Test Ticket',
      description: 'Description',
      status: TicketStatus.open,
      category: 'Bug',
      createdAt: now,
      userId: 'user-1',
      assignedTo: 'tech-1',
    );

    final resultWithAssignment = builder.build(
      ticket: assignedTicket,
      history: const [],
    );

    expect(
      resultWithAssignment.lifecycleMilestones[1].state,
      MilestoneState.current,
    );
  });

  test('In-progress mapping benar', () {
    final history = [
      TicketHistoryEntity(
        id: 'h1',
        ticketId: 'ticket-1',
        newStatus: 'in_progress',
        changedBy: 'tech-1',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ];

    final ticket = TicketEntity(
      id: 'ticket-1',
      title: 'Test Ticket',
      description: 'Description',
      status: TicketStatus.inProgress,
      category: 'Bug',
      createdAt: now.subtract(const Duration(hours: 2)),
      userId: 'user-1',
    );

    final result = builder.build(
      ticket: ticket,
      history: history,
    );

    expect(
      result.lifecycleMilestones[2].state,
      MilestoneState.current,
    );

    expect(
      result.lifecycleMilestones[2].timestamp,
      history.first.createdAt,
    );
  });

  test('Resolved mapping benar', () {
    final history = [
      TicketHistoryEntity(
        id: 'h1',
        ticketId: 'ticket-1',
        newStatus: 'resolved',
        changedBy: 'tech-1',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ];

    final ticket = TicketEntity(
      id: 'ticket-1',
      title: 'Test Ticket',
      description: 'Description',
      status: TicketStatus.resolved,
      category: 'Bug',
      createdAt: now.subtract(const Duration(hours: 2)),
      userId: 'user-1',
    );

    final result = builder.build(
      ticket: ticket,
      history: history,
    );

    expect(
      result.lifecycleMilestones[3].state,
      MilestoneState.current,
    );
  });

  test('Closed mapping benar', () {
    final ticket = TicketEntity(
      id: 'ticket-1',
      title: 'Test Ticket',
      description: 'Description',
      status: TicketStatus.closed,
      category: 'Bug',
      createdAt: now.subtract(const Duration(hours: 2)),
      userId: 'user-1',
    );

    final result = builder.build(
      ticket: ticket,
      history: const [],
    );

    expect(
      result.lifecycleMilestones[4].state,
      MilestoneState.current,
    );

    expect(result.isClosed, isTrue);
  });

  test('Pending menjadi activity event', () {
    final history = [
      TicketHistoryEntity(
        id: 'h1',
        ticketId: 'ticket-1',
        newStatus: 'pending',
        changedBy: 'tech-1',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ];

    final result = builder.build(
      ticket: tTicket,
      history: history,
    );

    expect(
      result.activityEvents.any(
        (event) => event.newStatus == 'pending',
      ),
      isTrue,
    );
  });

  test('Activity timeline chronological ascending', () {
    final commentTime = tTicket.createdAt.add(
      const Duration(hours: 1),
    );

    final history = [
      TicketHistoryEntity(
        id: 'history-comment',
        ticketId: tTicket.id,
        activityType: 'comment',
        changedBy: 'user-2',
        createdAt: commentTime,
      ),
    ];

    final result = builder.build(
      ticket: tTicket,
      history: history,
    );

    expect(result.activityEvents, hasLength(2));

    // Timeline lengkap dimulai dari aktivitas terlama.
    expect(
      result.activityEvents.first.type,
      'created',
    );

    expect(
      result.activityEvents.first.occurredAt,
      tTicket.createdAt,
    );

    // Aktivitas terbaru ditempatkan pada elemen terakhir.
    expect(
      result.activityEvents.last.type,
      'comment',
    );

    expect(
      result.activityEvents.last.occurredAt,
      commentTime,
    );

    expect(
      result.activityEvents.first.occurredAt.isBefore(
        result.activityEvents.last.occurredAt,
      ),
      isTrue,
    );

    expect(
      result.activityEvents.first.isCurrent,
      isFalse,
    );

    expect(
      result.activityEvents.last.isCurrent,
      isTrue,
    );
  });

  test('Duplicate identik dideduplicate', () {
    final history = [
      TicketHistoryEntity(
        id: 'h1',
        ticketId: 'ticket-1',
        activityType: 'ticket_created',
        changedBy: 'user-1',
        createdAt: tTicket.createdAt,
      ),
    ];

    final result = builder.build(
      ticket: tTicket,
      history: history,
    );

    expect(result.activityEvents, hasLength(1));
    expect(result.activityEvents.first.type, 'created');
  });
}
