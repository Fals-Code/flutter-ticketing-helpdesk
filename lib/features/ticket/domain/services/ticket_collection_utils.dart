import 'package:uts/core/constants/enums.dart';

import '../entities/ticket_entity.dart';
import '../value_objects/ticket_query.dart';

typedef TicketComparator = int Function(TicketEntity a, TicketEntity b);

int compareTicketsDeterministically(TicketEntity a, TicketEntity b) {
  final leftTimestamp = a.updatedAt ?? a.createdAt;
  final rightTimestamp = b.updatedAt ?? b.createdAt;
  final timestampOrder = rightTimestamp.compareTo(leftTimestamp);
  if (timestampOrder != 0) {
    return timestampOrder;
  }

  return b.id.compareTo(a.id);
}

List<TicketEntity> sortTicketsDeterministically(
    Iterable<TicketEntity> tickets) {
  final sorted = tickets.toList(growable: false);
  sorted.sort(compareTicketsDeterministically);
  return sorted;
}

bool matchesTicketQuery(
  TicketEntity ticket,
  TicketQuery query, {
  String? assignedToId,
}) {
  if (query.status != null && ticket.status != query.status) {
    return false;
  }

  if (query.category != null &&
      ticket.category.toLowerCase() != query.category!.toLowerCase()) {
    return false;
  }

  if (query.priority != null && ticket.priority != query.priority) {
    return false;
  }

  if (assignedToId != null && ticket.assignedTo != assignedToId) {
    return false;
  }

  if (query.startDate != null && ticket.createdAt.isBefore(query.startDate!)) {
    return false;
  }

  if (query.endDate != null && ticket.createdAt.isAfter(query.endDate!)) {
    return false;
  }

  final search = query.search?.toLowerCase();
  if (search != null && search.isNotEmpty) {
    final inTitle = ticket.title.toLowerCase().contains(search);
    final inDescription = ticket.description.toLowerCase().contains(search);
    if (!inTitle && !inDescription) {
      return false;
    }
  }

  return true;
}

List<TicketEntity> mergeTicketPage({
  required Iterable<TicketEntity> existing,
  required Iterable<TicketEntity> incoming,
}) {
  final merged = <String, TicketEntity>{};

  for (final ticket in existing) {
    merged[ticket.id] = ticket;
  }

  for (final ticket in incoming) {
    final previous = merged[ticket.id];
    if (previous == null) {
      merged[ticket.id] = ticket;
      continue;
    }

    final previousTimestamp = previous.updatedAt ?? previous.createdAt;
    final incomingTimestamp = ticket.updatedAt ?? ticket.createdAt;
    if (incomingTimestamp.isAfter(previousTimestamp) ||
        incomingTimestamp.isAtSameMomentAs(previousTimestamp)) {
      merged[ticket.id] = ticket;
    }
  }

  return sortTicketsDeterministically(merged.values);
}

List<TicketEntity> upsertRealtimeTicket({
  required Iterable<TicketEntity> existing,
  required TicketEntity incoming,
}) {
  return mergeTicketPage(
    existing: existing,
    incoming: [incoming],
  );
}

List<TicketEntity> removeRealtimeTicket(
  Iterable<TicketEntity> existing,
  String ticketId,
) {
  return existing
      .where((ticket) => ticket.id != ticketId)
      .toList(growable: false);
}

List<TicketEntity> applyRealtimeSnapshot({
  required Iterable<TicketEntity> currentItems,
  required Iterable<TicketEntity> snapshotItems,
  required TicketQuery query,
  required bool hasMore,
  String? assignedToId,
}) {
  final filtered = sortTicketsDeterministically(
    snapshotItems.where(
      (ticket) => matchesTicketQuery(
        ticket,
        query,
        assignedToId: assignedToId,
      ),
    ),
  );

  if (!hasMore) {
    return filtered;
  }

  final targetCount = currentItems.length;
  if (targetCount <= 0) {
    return filtered.take(query.limit).toList(growable: false);
  }

  return filtered.take(targetCount).toList(growable: false);
}

TicketStatusFilter ticketStatusFilterFromQuery(TicketQuery query) {
  return switch (query.status) {
    TicketStatus.open => TicketStatusFilter.open,
    TicketStatus.pending => TicketStatusFilter.pending,
    TicketStatus.inProgress => TicketStatusFilter.inProgress,
    TicketStatus.resolved => TicketStatusFilter.resolved,
    TicketStatus.closed => TicketStatusFilter.closed,
    TicketStatus.reopened => TicketStatusFilter.reopened,
    null => TicketStatusFilter.all,
  };
}

TicketQuery applyStatusFilterToQuery(
  TicketQuery query,
  TicketStatusFilter filter,
) {
  return query.copyWith(
    status: switch (filter) {
      TicketStatusFilter.open => TicketStatus.open,
      TicketStatusFilter.pending => TicketStatus.pending,
      TicketStatusFilter.inProgress => TicketStatus.inProgress,
      TicketStatusFilter.resolved => TicketStatus.resolved,
      TicketStatusFilter.closed => TicketStatus.closed,
      TicketStatusFilter.reopened => TicketStatus.reopened,
      TicketStatusFilter.all => null,
    },
    clearStatus: filter == TicketStatusFilter.all,
    page: 0,
    offset: 0,
  );
}
