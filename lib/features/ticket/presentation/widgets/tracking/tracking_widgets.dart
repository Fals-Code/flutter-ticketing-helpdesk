import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_tracking_item.dart';
import 'package:uts/features/ticket/domain/entities/ticket_tracking_view_data.dart';

class TicketTrackingSummaryCard extends StatelessWidget {
  final bool isDark;
  final TicketEntity ticket;

  const TicketTrackingSummaryCard({
    super.key,
    required this.isDark,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${ticket.id.substring(0, ticket.id.length > 8 ? 8 : ticket.id.length).toUpperCase()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
              StatusBadge(status: ticket.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ticket.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              InfoItem(
                label: 'Dibuat',
                value: DateFormat('dd MMM yyyy').format(ticket.createdAt),
                isDark: isDark,
              ),
              const SizedBox(width: 24),
              InfoItem(
                label: 'Pelapor',
                value: ticket.userName ?? 'User',
                isDark: isDark,
              ),
              if (ticket.assignedToName != null) ...[
                const SizedBox(width: 24),
                InfoItem(
                  label: 'Petugas',
                  value: ticket.assignedToName!,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final TicketStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: status.color,
        ),
      ),
    );
  }
}

class InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const InfoItem({
    super.key,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class TicketLifecycleProgress extends StatelessWidget {
  final bool isDark;
  final List<TicketLifecycleMilestone> milestones;

  const TicketLifecycleProgress({
    super.key,
    required this.isDark,
    required this.milestones,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(milestones.length, (index) {
        final milestone = milestones[index];
        final isLast = index == milestones.length - 1;

        return TicketLifecycleStepTile(
          milestone: milestone,
          isDark: isDark,
          isLast: isLast,
        );
      }),
    );
  }
}

class TicketLifecycleStepTile extends StatelessWidget {
  final TicketLifecycleMilestone milestone;
  final bool isDark;
  final bool isLast;

  const TicketLifecycleStepTile({
    super.key,
    required this.milestone,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (milestone.state) {
      MilestoneState.completed => AppColors.success,
      MilestoneState.current => AppColors.primary,
      MilestoneState.pending => isDark ? Colors.white12 : Colors.black12,
      MilestoneState.interrupted => AppColors.danger,
    };

    final icon = switch (milestone.state) {
      MilestoneState.completed => Icons.check_circle_rounded,
      MilestoneState.current => Icons.radio_button_checked_rounded,
      MilestoneState.pending => Icons.radio_button_off_rounded,
      MilestoneState.interrupted => Icons.error_rounded,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Icon(icon, size: 20, color: color),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: color.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: milestone.state == MilestoneState.pending
                          ? FontWeight.w500
                          : FontWeight.w700,
                      color: milestone.state == MilestoneState.pending
                          ? (isDark ? Colors.white38 : Colors.black38)
                          : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  if (milestone.timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm')
                          .format(milestone.timestamp!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TicketActivityTimeline extends StatelessWidget {
  final bool isDark;
  final List<TicketTrackingItem> items;

  const TicketActivityTimeline({
    super.key,
    required this.isDark,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return TicketActivityTile(
          item: items[index],
          isDark: isDark,
          isLast: index == items.length - 1,
        );
      },
    );
  }
}

class TicketActivityTile extends StatelessWidget {
  final TicketTrackingItem item;
  final bool isDark;
  final bool isLast;

  const TicketActivityTile({
    super.key,
    required this.item,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ActivityIcon(type: item.type),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (item.isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Terbaru',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.description,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (item.actorName != null && item.actorName!.isNotEmpty)
                ActivityMetaChip(
                  label: item.actorName!,
                  isDark: isDark,
                  icon: Icons.person_outline_rounded,
                ),
              ActivityMetaChip(
                label: DateFormat('dd MMM, HH:mm').format(item.occurredAt),
                isDark: isDark,
                icon: Icons.schedule_rounded,
              ),
              if (item.newStatus != null && item.oldStatus != null)
                ActivityMetaChip(
                  label: '${item.oldStatus} → ${item.newStatus}',
                  isDark: isDark,
                  icon: Icons.swap_horiz_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActivityIcon extends StatelessWidget {
  final String? type;

  const ActivityIcon({super.key, this.type});

  @override
  Widget build(BuildContext context) {
    final IconData iconData = switch (type?.toLowerCase()) {
      'created' => Icons.add_task_rounded,
      'comment' => Icons.comment_outlined,
      'attachment_upload' => Icons.attach_file_rounded,
      'in_progress' => Icons.play_circle_outline_rounded,
      'resolved' => Icons.check_circle_outline_rounded,
      'closed' => Icons.lock_outline_rounded,
      'reopened' => Icons.refresh_rounded,
      'pending' => Icons.pause_circle_outline_rounded,
      _ => Icons.info_outline_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        size: 18,
        color: AppColors.primary,
      ),
    );
  }
}

class ActivityMetaChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final IconData icon;

  const ActivityMetaChip({
    super.key,
    required this.label,
    required this.isDark,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
