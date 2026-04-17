import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_strings.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:uts/features/notification/domain/entities/notification_entity.dart';
import 'package:uts/core/utils/date_helper.dart';
import 'package:uts/core/utils/haptic_helper.dart';
import 'package:uts/core/services/toast_service.dart';

class NotificationTab extends StatelessWidget {
  const NotificationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ToastService().show(context, message: state.errorMessage!, type: ToastType.error);
        }
      },
      builder: (context, state) {
        final unreadCount = state.notifications.where((n) => !n.isRead).length;

        return Scaffold(
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          appBar: _buildAppBar(context, state, unreadCount, isDark),
          body: state.isLoading && state.notifications.isEmpty
              ? _buildSkeleton(isDark)
              : state.notifications.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildNotificationList(context, state, isDark),
          floatingActionButton: state.selectionMode && state.selectedIds.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => _handleBatchDelete(context, state),
                  label: Text(
                    'Hapus ${state.selectedIds.length} Notifikasi',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.delete_sweep_rounded),
                  backgroundColor: AppColors.danger,
                )
              : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, NotificationState state, int unreadCount, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: state.selectionMode
            ? IconButton(
                key: const ValueKey('close'),
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  HapticHelper.light();
                  context.read<NotificationBloc>().add(ToggleSelectionModeRequested());
                },
              )
            : null,
      ),
      title: Row(
        children: [
          Text(
            state.selectionMode ? '${state.selectedIds.length} Terpilih' : AppStrings.navNotifications,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          if (!state.selectionMode && unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (state.notifications.isNotEmpty) _buildPopupMenu(context, state),
        const SizedBox(width: 8),
      ],
    );
  }

  void _handleBatchDelete(BuildContext context, NotificationState state) {
    HapticHelper.heavy();
    context.read<NotificationBloc>().add(DeleteSelectedNotificationsRequested());
    ToastService().show(context, message: '${state.selectedIds.length} notifikasi dihapus', type: ToastType.success);
  }

  Widget _buildNotificationList(BuildContext context, NotificationState state, bool isDark) {
    return RefreshIndicator(
      onRefresh: () async => context.read<NotificationBloc>().add(FetchNotificationsRequested()),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: state.notifications.length,
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          final isSelected = state.selectedIds.contains(notification.id);
          
          return Dismissible(
            key: Key('notif_${notification.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            ),
            onDismissed: (direction) {
              HapticHelper.medium();
              context.read<NotificationBloc>().add(DeleteNotificationRequested(notification.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notifikasi dihapus'),
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Urungkan',
                    textColor: Colors.white,
                    onPressed: () {
                      // Logic untuk undo bisa ditambahkan di BLoC jika didukung
                    },
                  ),
                ),
              );
            },
            child: _NotificationCard(
              notification: notification,
              isDark: isDark,
              isSelectionMode: state.selectionMode,
              isSelected: isSelected,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, size: 80, color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 24),
          Text(
            'Semua Sudah Terbaca!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ketuk untuk menyegarkan jika ada yang tertinggal.',
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
    HapticHelper.light();
    switch (value) {
      case 'read_all': 
        bloc.add(MarkAllReadRequested()); 
        ToastService().show(context, message: 'Semua notifikasi dibaca', type: ToastType.success);
        break;
      case 'pilih': bloc.add(ToggleSelectionModeRequested()); break;
      case 'select_all': bloc.add(SelectAllNotificationsRequested()); break;
      case 'delete_all': 
        HapticHelper.heavy();
        bloc.add(DeleteAllNotificationsRequested());
        ToastService().show(context, message: 'Semua notifikasi dihapus', type: ToastType.success);
        break;
    }
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
          HapticHelper.medium();
          context.read<NotificationBloc>().add(ToggleSelectionModeRequested());
          context.read<NotificationBloc>().add(ToggleNotificationSelectionRequested(notification.id));
        }
      },
      onTap: () {
        HapticHelper.light();
        if (isSelectionMode) {
          context.read<NotificationBloc>().add(ToggleNotificationSelectionRequested(notification.id));
        } else {
          context.read<NotificationBloc>().add(MarkReadRequested(notification.id));
          if (notification.ticketId != null) {
            context.push(AppRoutes.ticketDetail.replaceAll(':id', notification.ticketId!));
          }
        }
      },
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : unread 
                      ? AppColors.primary.withValues(alpha: 0.03) 
                      : (isDark ? AppColors.surfaceDark : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
              ] : [],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unread)
                    Container(
                      width: 3,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isSelectionMode ? 32 : 0,
                    child: isSelectionMode 
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) {
                            HapticHelper.selection();
                            context.read<NotificationBloc>().add(ToggleNotificationSelectionRequested(notification.id));
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          activeColor: AppColors.primary,
                        )
                      : const SizedBox.shrink(),
                  ),
                  if (isSelectionMode) const SizedBox(width: 12),

                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: unread ? AppColors.primary.withValues(alpha: 0.1) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      unread ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                      size: 18,
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
                            fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          DateHelper.formatRelative(notification.createdAt),
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white24 : Colors.black26,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
