import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/features/ticket/domain/entities/ticket_history_entity.dart';

class TicketTimelineWidget extends StatelessWidget {
  final List<TicketHistoryEntity> activities;
  final bool isDark;

  const TicketTimelineWidget({
    super.key,
    required this.activities,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(
                Icons.timeline_rounded,
                size: 32,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada riwayat aktivitas.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final List<TicketHistoryEntity> visibleActivities =
        _prepareActivities(activities);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleActivities.length,
      itemBuilder: (context, index) {
        final TicketHistoryEntity activity = visibleActivities[index];
        final bool isLast = index == visibleActivities.length - 1;
        final Color color = _getActivityColor(activity.newStatus);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    const SizedBox(height: 2),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: CustomPaint(
                          painter: _DashedLinePainter(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getActivityTitle(activity),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getActivityDescription(activity),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (activity.changedByName?.isNotEmpty == true) ...[
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  activity.changedByName![0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'oleh ${activity.changedByName}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _relativeTime(activity.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<TicketHistoryEntity> _prepareActivities(
    List<TicketHistoryEntity> source,
  ) {
    if (source.length < 2) {
      return source;
    }

    final List<TicketHistoryEntity> result = <TicketHistoryEntity>[];
    int index = 0;

    while (index < source.length) {
      final TicketHistoryEntity current = source[index];

      if (index + 1 < source.length) {
        final TicketHistoryEntity next = source[index + 1];

        if (_isAssignmentStartPair(current, next)) {
          final TicketHistoryEntity statusActivity =
              current.eventType.toLowerCase() == 'status_changed'
                  ? current
                  : next;
          final TicketHistoryEntity assignmentActivity =
              current.eventType.toLowerCase() == 'assigned' ? current : next;

          result.add(
            TicketHistoryEntity(
              id: '${assignmentActivity.id}:${statusActivity.id}',
              ticketId: statusActivity.ticketId,
              eventType: 'assignment_started',
              oldStatus: statusActivity.oldStatus,
              newStatus: statusActivity.newStatus,
              changedBy: statusActivity.changedBy,
              changedByName: statusActivity.changedByName ??
                  assignmentActivity.changedByName,
              createdAt: current.createdAt.isAfter(next.createdAt)
                  ? current.createdAt
                  : next.createdAt,
            ),
          );

          index += 2;
          continue;
        }
      }

      result.add(current);
      index++;
    }

    return result;
  }

  bool _isAssignmentStartPair(
    TicketHistoryEntity first,
    TicketHistoryEntity second,
  ) {
    final Set<String> eventTypes = <String>{
      first.eventType.toLowerCase(),
      second.eventType.toLowerCase(),
    };

    final bool containsExpectedEvents = eventTypes.contains('assigned') &&
        eventTypes.contains('status_changed');
    final bool sameTicket = first.ticketId == second.ticketId;
    final bool sameActor = first.changedBy == second.changedBy;
    final bool sameOldStatus = first.oldStatus == second.oldStatus;
    final bool sameNewStatus = first.newStatus == second.newStatus;
    final bool startsProgress =
        first.newStatus.toLowerCase() == 'in_progress';
    final int timeDifference =
        first.createdAt.difference(second.createdAt).inSeconds.abs();

    return containsExpectedEvents &&
        sameTicket &&
        sameActor &&
        sameOldStatus &&
        sameNewStatus &&
        startsProgress &&
        timeDifference <= 3;
  }

  String _relativeTime(DateTime dt) {
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  Color _getActivityColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.statusOpen;
      case 'pending':
        return Colors.amber;
      case 'in_progress':
        return AppColors.statusInProgress;
      case 'resolved':
        return AppColors.statusResolved;
      case 'closed':
        return AppColors.textSecondaryDark;
      case 'reopened':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  String _getActivityTitle(TicketHistoryEntity activity) {
    switch (activity.eventType.toLowerCase()) {
      case 'ticket_created':
        return 'Tiket Dibuat';
      case 'assignment_started':
        return 'Ditugaskan & Mulai Dikerjakan';
      case 'assigned':
        return 'Ditugaskan ke Teknisi';
      case 'unassigned':
        return 'Penugasan Dibatalkan';
      case 'comment_added':
        return 'Komentar Ditambahkan';
      case 'attachment_uploaded':
        return 'Lampiran Ditambahkan';
      case 'attachment_deleted':
        return 'Lampiran Dihapus';
      case 'ticket_deleted':
        return 'Tiket Dihapus';
      case 'ticket_restored':
        return 'Tiket Dipulihkan';
      case 'admin_override':
      case 'status_changed':
        return _statusActivityTitle(activity.newStatus);
      default:
        if (activity.oldStatus == null) {
          return 'Tiket Dibuat';
        }
        return _statusActivityTitle(activity.newStatus);
    }
  }

  String _statusActivityTitle(String newStatus) {
    switch (newStatus.toLowerCase()) {
      case 'open':
        return 'Tiket Dibuka';
      case 'pending':
        return 'Menunggu Tindak Lanjut';
      case 'in_progress':
        return 'Mulai Dikerjakan';
      case 'resolved':
        return 'Penanganan Selesai';
      case 'closed':
        return 'Tiket Ditutup';
      case 'reopened':
        return 'Tiket Dibuka Kembali';
      default:
        return 'Status Diperbarui';
    }
  }

  String _getActivityDescription(TicketHistoryEntity activity) {
    switch (activity.eventType.toLowerCase()) {
      case 'ticket_created':
        return 'Tiket berhasil dibuat dengan status Terbuka.';
      case 'assignment_started':
        return 'Tiket ditugaskan kepada teknisi dan status berubah dari '
            '${_nullableStatusLabel(activity.oldStatus)} menjadi '
            '${_statusLabel(activity.newStatus)}.';
      case 'assigned':
        return 'Tiket telah ditugaskan kepada teknisi.';
      case 'unassigned':
        return 'Penugasan teknisi pada tiket dibatalkan.';
      case 'comment_added':
        return 'Komentar baru ditambahkan pada tiket.';
      case 'attachment_uploaded':
        return 'Lampiran baru ditambahkan pada tiket.';
      case 'attachment_deleted':
        return 'Lampiran dihapus dari tiket.';
      case 'ticket_deleted':
        return 'Tiket dihapus sesuai kebijakan sistem.';
      case 'ticket_restored':
        return 'Tiket berhasil dipulihkan.';
      case 'admin_override':
        return 'Status tiket diperbarui oleh Administrator dari '
            '${_nullableStatusLabel(activity.oldStatus)} menjadi '
            '${_statusLabel(activity.newStatus)}.';
      case 'status_changed':
        return 'Status berubah dari '
            '${_nullableStatusLabel(activity.oldStatus)} menjadi '
            '${_statusLabel(activity.newStatus)}.';
      default:
        if (activity.oldStatus == null) {
          return 'Aktivitas tiket berhasil dicatat.';
        }
        return 'Status berubah dari ${_statusLabel(activity.oldStatus!)} '
            'menjadi ${_statusLabel(activity.newStatus)}.';
    }
  }

  String _nullableStatusLabel(String? status) {
    if (status == null || status.isEmpty) {
      return 'status sebelumnya';
    }
    return _statusLabel(status);
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Terbuka';
      case 'pending':
        return 'Menunggu';
      case 'in_progress':
        return 'Diproses';
      case 'resolved':
        return 'Selesai';
      case 'closed':
        return 'Ditutup';
      case 'reopened':
        return 'Dibuka Kembali';
      default:
        return status;
    }
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double startY = 4;
    const double dashLength = 4;
    const double dashGap = 4;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashLength),
        paint,
      );
      startY += dashLength + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
