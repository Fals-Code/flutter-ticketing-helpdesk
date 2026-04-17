import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_strings.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:uts/features/notification/domain/entities/notification_entity.dart';

class NotificationTab extends StatelessWidget {
  const NotificationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          appBar: _buildAppBar(context, state, isDark),
          body: state.isLoading && state.notifications.isEmpty
              ? _buildSkeleton(isDark)
              : state.notifications.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildNotificationList(context, state, isDark),
          floatingActionButton: state.selectionMode && state.selectedIds.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => _showDeleteConfirm(context, selected: true),
                  label: Text('Hapus (${state.selectedIds.length})', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  icon: const Icon(Icons.delete_sweep_rounded),
                  backgroundColor: AppColors.danger,
                )
              : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, NotificationState state, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: state.selectionMode
          ? IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.read<NotificationBloc>().add(ToggleSelectionModeRequested()),
            )
          : null,
      title: Text(
        state.selectionMode ? '${state.selectedIds.length} Terpilih' : AppStrings.navNotifications,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      actions: [
        if (state.notifications.isNotEmpty) _buildPopupMenu(context, state),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNotificationList(BuildContext context, NotificationState state, bool isDark) {
    final grouped = _groupNotifications(state.notifications);

    return RefreshIndicator(
      onRefresh: () async => context.read<NotificationBloc>().add(FetchNotificationsRequested()),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final entry = grouped.entries.elementAt(index);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 24, bottom: 12),
                child: Text(
                  entry.key.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white24 : Colors.black26,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              ...entry.value.map((notification) {
                final isSelected = state.selectedIds.contains(notification.id);
                return _NotificationCard(
                  notification: notification,
                  isDark: isDark,
                  isSelectionMode: state.selectionMode,
                  isSelected: isSelected,
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<NotificationEntity>> _groupNotifications(List<NotificationEntity> notifications) {
    final Map<String, List<NotificationEntity>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var n in notifications) {
      final date = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      String key;
      if (date == today) {
        key = 'Hari Ini';
      } else if (date == yesterday) {
        key = 'Kemarin';
      } else {
        key = DateFormat('dd MMMM yyyy', 'id_ID').format(date);
      }

      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(n);
    }
    return groups;
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Kosong',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada notifikasi baru untuk Anda.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, NotificationState state) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) => _handleMenuAction(context, val, state),
      itemBuilder: (context) {
        final hasUnread = state.notifications.any((n) => !n.isRead);
        final isAllSelected = state.selectedIds.length == state.notifications.length;
        return [
          if (!state.selectionMode) ...[
            PopupMenuItem(
              value: 'read_all',
              enabled: hasUnread,
              child: const _PopupItem(icon: Icons.done_all_rounded, label: 'Baca Semua'),
            ),
            const PopupMenuItem(
              value: 'pilih',
              child: _PopupItem(icon: Icons.checklist_rounded, label: 'Pilih'),
            ),
          ],
          if (state.selectionMode) ...[
             PopupMenuItem(
              value: 'select_all',
              child: _PopupItem(
                icon: isAllSelected ? Icons.deselect_rounded : Icons.select_all_rounded, 
                label: isAllSelected ? 'Batal Pilih Semua' : 'Pilih Semua'
              ),
            ),
          ],
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete_all',
            child: _PopupItem(icon: Icons.delete_forever_rounded, label: 'Hapus Semua', isDestructive: true),
          ),
        ];
      },
    );
  }

  void _handleMenuAction(BuildContext context, String value, NotificationState state) {
    final bloc = context.read<NotificationBloc>();
    switch (value) {
      case 'read_all': bloc.add(MarkAllReadRequested()); break;
      case 'pilih': bloc.add(ToggleSelectionModeRequested()); break;
      case 'select_all': bloc.add(SelectAllNotificationsRequested()); break;
      case 'delete_all': _showDeleteConfirm(context, selected: false); break;
    }
  }

  void _showDeleteConfirm(BuildContext context, {required bool selected}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Notifikasi', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text(
          selected 
              ? 'Yakin ingin menghapus notifikasi yang dipilih?' 
              : 'Yakin ingin menghapus seluruh riwayat notifikasi?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey))),
          TextButton(
            onPressed: () {
              if (selected) {
                context.read<NotificationBloc>().add(DeleteSelectedNotificationsRequested());
              } else {
                context.read<NotificationBloc>().add(DeleteAllNotificationsRequested());
              }
              Navigator.pop(ctx);
            },
            child: Text('Hapus', style: GoogleFonts.inter(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification; 
  final bool isDark;
  final bool isSelectionMode;
  final bool isSelected;

  const _NotificationCard({
    required this.notification, 
    required this.isDark,
    required this.isSelectionMode,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    
    return GestureDetector(
      onLongPress: () {
        if (!isSelectionMode) {
          context.read<NotificationBloc>().add(ToggleSelectionModeRequested());
          context.read<NotificationBloc>().add(ToggleNotificationSelectionRequested(notification.id));
        }
      },
      onTap: () {
        if (isSelectionMode) {
          context.read<NotificationBloc>().add(ToggleNotificationSelectionRequested(notification.id));
        } else {
          context.read<NotificationBloc>().add(MarkReadRequested(notification.id));
          if (notification.ticketId != null) {
            context.push(AppRoutes.ticketDetail.replaceAll(':id', notification.ticketId!));
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : unread 
                  ? AppColors.primary.withValues(alpha: 0.03) 
                  : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : unread 
                    ? AppColors.primary.withValues(alpha: 0.2) 
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSelectionMode) ...[
              SizedBox(
                width: 24, height: 24,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => context.read<NotificationBloc>().add(ToggleNotificationSelectionRequested(notification.id)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  activeColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
            ],
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: unread ? AppColors.primary.withValues(alpha: 0.1) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                unread ? Icons.notifications_active_rounded : Icons.notifications_rounded,
                size: 20,
                color: unread ? AppColors.primary : (isDark ? Colors.white24 : Colors.black26),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: GoogleFonts.inter(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 12, color: isDark ? Colors.white24 : Colors.black26),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm').format(notification.createdAt),
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white24 : Colors.black26,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (unread && !isSelectionMode)
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8, height: 8,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

class _PopupItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  const _PopupItem({required this.icon, required this.label, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDestructive ? AppColors.danger : null),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: isDestructive ? AppColors.danger : null)),
      ],
    );
  }
}
