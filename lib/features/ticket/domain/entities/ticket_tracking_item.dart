import 'package:equatable/equatable.dart';

import 'ticket_history_entity.dart';

class TicketTrackingItem extends Equatable {
  final String id;
  final String ticketId;
  final String title;
  final String description;
  final String? actorName;
  final DateTime occurredAt;
  final String? oldStatus;
  final String? newStatus;
  final String? type;
  final bool isCompleted;
  final bool isCurrent;

  const TicketTrackingItem({
    required this.id,
    required this.ticketId,
    required this.title,
    required this.description,
    this.actorName,
    required this.occurredAt,
    this.oldStatus,
    this.newStatus,
    this.type,
    this.isCompleted = true,
    this.isCurrent = false,
  });

  factory TicketTrackingItem.fromHistory(TicketHistoryEntity history) {
    final normalizedType = history.activityType?.trim().toLowerCase();
    final normalizedNewStatus = history.newStatus?.trim().toLowerCase();
    final title = switch (normalizedType) {
      'comment' => 'Komentar Ditambahkan',
      'attachment_upload' => 'Lampiran Ditambahkan',
      'attachment_delete' => 'Lampiran Dihapus',
      'ticket_created' => 'Tiket Dibuat',
      _ => _titleFromStatus(history.oldStatus, history.newStatus),
    };

    final description = history.description?.trim().isNotEmpty == true
        ? history.description!.trim()
        : _descriptionFromHistory(history);

    return TicketTrackingItem(
      id: history.id,
      ticketId: history.ticketId,
      title: title,
      description: description,
      actorName: history.changedByName,
      occurredAt: history.createdAt,
      oldStatus: history.oldStatus,
      newStatus: history.newStatus,
      type: normalizedType ?? normalizedNewStatus,
      isCompleted: true,
      isCurrent: false,
    );
  }

  static String _titleFromStatus(String? oldStatus, String? newStatus) {
    if (oldStatus == null && newStatus == null) {
      return 'Aktivitas Tiket';
    }
    if (oldStatus == null) {
      return 'Tiket Dibuat';
    }

    return switch (newStatus?.trim().toLowerCase()) {
      'in_progress' => 'Mulai Dikerjakan',
      'resolved' => 'Penanganan Selesai',
      'closed' => 'Tiket Ditutup',
      'reopened' => 'Tiket Dibuka Kembali',
      'pending' => 'Tiket Ditunda',
      _ => 'Status Diperbarui',
    };
  }

  static String _descriptionFromHistory(TicketHistoryEntity history) {
    if (history.oldStatus == null && history.newStatus == null) {
      return 'Aktivitas tiket tercatat.';
    }
    if (history.oldStatus == null) {
      return 'Tiket berhasil dibuat.';
    }
    if (history.newStatus == null) {
      return 'Riwayat tiket diperbarui.';
    }
    return 'Status berubah dari ${history.oldStatus} menjadi ${history.newStatus}.';
  }

  @override
  List<Object?> get props => [
        id,
        ticketId,
        title,
        description,
        actorName,
        occurredAt,
        oldStatus,
        newStatus,
        type,
        isCompleted,
        isCurrent,
      ];
}
