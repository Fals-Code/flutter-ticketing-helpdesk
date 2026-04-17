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
              Icon(Icons.timeline_rounded, size: 32, color: isDark ? Colors.white24 : Colors.black26),
              const SizedBox(height: 12),
              Text(
                'Belum ada riwayat aktivitas.',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        final isLast = index == activities.length - 1;
        final color = _getActivityColor(activity.newStatus);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline column (left)
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
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getActivityTitle(activity.oldStatus, activity.newStatus),
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
                          if (activity.changedByName != null) ...[
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
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'oleh ${activity.changedByName}',
                              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _relativeTime(activity.createdAt),
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
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

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  Color _getActivityColor(String status) {
    switch (status.toLowerCase()) {
      case 'open': return AppColors.statusOpen;
      case 'in_progress': return AppColors.statusInProgress;
      case 'resolved': return AppColors.statusResolved;
      case 'closed': return AppColors.textSecondaryDark;
      default: return AppColors.primary;
    }
  }

  String _getActivityTitle(String? oldStatus, String newStatus) {
    if (oldStatus == null) return 'Tiket Dibuat';
    switch (newStatus.toLowerCase()) {
      case 'in_progress': return 'Mulai Dikerjakan';
      case 'resolved': return 'Penanganan Selesai';
      case 'closed': return 'Tiket Ditutup';
      default: return 'Status Diperbarui';
    }
  }

  String _getActivityDescription(TicketHistoryEntity activity) {
    if (activity.oldStatus == null) return 'Tiket berhasil dibuat dengan status Terbuka.';
    final oldLabel = _statusLabel(activity.oldStatus!);
    final newLabel = _statusLabel(activity.newStatus);
    return 'Status berubah dari $oldLabel menjadi $newLabel.';
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open': return 'Terbuka';
      case 'in_progress': return 'Diproses';
      case 'resolved': return 'Selesai';
      case 'closed': return 'Ditutup';
      default: return status;
    }
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double startY = 4;
    const dashLength = 4.0;
    const dashGap = 4.0;

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
