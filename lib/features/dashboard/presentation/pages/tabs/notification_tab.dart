import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:uts/features/notification/domain/entities/notification_entity.dart';

class NotificationTab extends StatelessWidget {
  const NotificationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7F8FA),
      appBar: _buildAppBar(context, isDark),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state.isLoading && state.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            );
          }

          if (state.notifications.isEmpty) {
            return _buildEmptyState(context, isDark);
          }

          final unread = state.notifications.where((n) => !n.isRead).toList();
          final read = state.notifications.where((n) => n.isRead).toList();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<NotificationBloc>().add(FetchNotificationsRequested());
            },
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                if (unread.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader('Belum Dibaca', unread.length, isDark),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _NotificationCard(
                        notification: unread[index],
                        isDark: isDark,
                      ),
                      childCount: unread.length,
                    ),
                  ),
                ],
                if (read.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader('Sudah Dibaca', null, isDark),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _NotificationCard(
                        notification: read[index],
                        isDark: isDark,
                      ),
                      childCount: read.length,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      title: const Text(
        'Notifikasi',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7F8FA),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: [
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            final unreadCount = state.notifications.where((n) => !n.isRead).length;
            if (unreadCount == 0) return const SizedBox.shrink();
            return TextButton.icon(
              onPressed: () =>
                  context.read<NotificationBloc>().add(MarkAllReadRequested()),
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: const Text('Tandai Semua', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: () =>
              context.read<NotificationBloc>().add(FetchNotificationsRequested()),
          tooltip: 'Muat ulang',
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int? count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white54 : Colors.black45,
              letterSpacing: 0.5,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tidak ada notifikasi',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Update tiket akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final bool isDark;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final timeStr = _formatTime(notification.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Mark as read first
            if (unread) {
              context
                  .read<NotificationBloc>()
                  .add(MarkReadRequested(notification.id));
            }
            // Then navigate
            if (notification.ticketId != null && notification.ticketId!.isNotEmpty) {
              context.push(
                AppRoutes.ticketDetail.replaceAll(':id', notification.ticketId!),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: unread
                  ? (isDark
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.05))
                  : (isDark ? AppColors.surfaceDark : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: unread
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : (isDark
                        ? AppColors.borderDark
                        : const Color(0xFFEEEEF2)),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(unread),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white60
                              : Colors.black54,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (notification.ticketId != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.confirmation_number_outlined,
                                    size: 11,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '#${notification.ticketId!.substring(0, 8).toUpperCase()}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (unread)
                              GestureDetector(
                                onTap: () => context
                                    .read<NotificationBloc>()
                                    .add(MarkReadRequested(notification.id)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Text(
                                    'Tandai dibaca',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 3),
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool unread) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: unread
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        unread
            ? Icons.notifications_active_rounded
            : Icons.notifications_none_rounded,
        size: 20,
        color: unread ? AppColors.primary : Colors.grey,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return DateFormat('dd MMM').format(dt);
  }
}
