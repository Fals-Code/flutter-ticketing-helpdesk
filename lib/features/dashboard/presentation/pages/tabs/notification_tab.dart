import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
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

    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: state.selectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.read<NotificationBloc>().add(ToggleSelectionModeRequested()),
                  )
                : null,
            title: Text(
              state.selectionMode 
                  ? '${state.selectedIds.length} terpilih' 
                  : AppStrings.navNotifications
            ),
            actions: [
              if (state.notifications.isNotEmpty)
                _NotificationPopupMenu(state: state),
            ],
          ),
          body: state.isLoading && state.notifications.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.notifications.isEmpty
                  ? _EmptyState(isDark: isDark)
                  : RefreshIndicator(
                      onRefresh: () async {
                        context.read<NotificationBloc>().add(FetchNotificationsRequested());
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spaceMD,
                          vertical: AppDimensions.spaceMD,
                        ),
                        itemCount: state.notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spaceSM),
                        itemBuilder: (context, index) {
                          final notification = state.notifications[index];
                          final isSelected = state.selectedIds.contains(notification.id);
                          
                          return _NotificationCard(
                            notification: notification, 
                            isDark: isDark,
                            isSelectionMode: state.selectionMode,
                            isSelected: isSelected,
                          );
                        },
                      ),
                    ),
          floatingActionButton: state.selectionMode && state.selectedIds.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => _showDeleteConfirm(context, selected: true),
                  label: const Text('Hapus yang dipilih'),
                  icon: const Icon(Icons.delete_outline),
                  backgroundColor: Colors.redAccent,
                )
              : null,
        );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context, {required bool selected}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(selected ? 'Hapus Terpilih' : 'Hapus Semua'),
        content: Text(selected 
            ? 'Apakah Anda yakin ingin menghapus notifikasi yang dipilih?' 
            : 'Apakah Anda yakin ingin menghapus semua notifikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              if (selected) {
                context.read<NotificationBloc>().add(DeleteSelectedNotificationsRequested());
              } else {
                context.read<NotificationBloc>().add(DeleteAllNotificationsRequested());
              }
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _NotificationPopupMenu extends StatelessWidget {
  final NotificationState state;
  const _NotificationPopupMenu({required this.state});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        final bloc = context.read<NotificationBloc>();
        switch (value) {
          case 'read_all':
            bloc.add(MarkAllReadRequested());
            break;
          case 'pilih':
            bloc.add(ToggleSelectionModeRequested());
            break;
          case 'select_all':
            bloc.add(SelectAllNotificationsRequested());
            break;
          case 'delete_all':
            _showDeleteConfirmDialog(context, bloc, selected: false);
            break;
          case 'delete_selected':
            _showDeleteConfirmDialog(context, bloc, selected: true);
            break;
        }
      },
      itemBuilder: (context) {
        final hasUnread = state.notifications.any((n) => !n.isRead);
        final isAllSelected = state.selectedIds.length == state.notifications.length;
        
        return [
          if (!state.selectionMode) ...[
            PopupMenuItem(
              value: 'read_all',
              enabled: hasUnread,
              child: const Row(
                children: [
                  Icon(Icons.done_all, size: 20),
                  SizedBox(width: 12),
                  Text('Baca Semua'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'pilih',
              child: Row(
                children: [
                  Icon(Icons.checklist, size: 20),
                  SizedBox(width: 12),
                  Text('Pilih'),
                ],
              ),
            ),
          ],
          if (state.selectionMode) ...[
             PopupMenuItem(
              value: 'select_all',
              child: Row(
                children: [
                  Icon(isAllSelected ? Icons.deselect : Icons.select_all, size: 20),
                  SizedBox(width: 12),
                  Text(isAllSelected ? 'Batal Pilih Semua' : 'Pilih Semua'),
                ],
              ),
            ),
            if (state.selectedIds.isNotEmpty)
              const PopupMenuItem(
                value: 'delete_selected',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Hapus yang dipilih', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
          if (!state.selectionMode || state.selectedIds.isEmpty)
            const PopupMenuItem(
              value: 'delete_all',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Hapus Semua', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
        ];
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, NotificationBloc bloc, {required bool selected}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(selected ? 'Hapus Terpilih' : 'Hapus Semua'),
        content: Text(selected 
            ? 'Hapus ${state.selectedIds.length} notifikasi terpilih?' 
            : 'Apakah Anda yakin ingin menghapus semua notifikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              if (selected) {
                bloc.add(DeleteSelectedNotificationsRequested());
              } else {
                bloc.add(DeleteAllNotificationsRequested());
              }
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Belum ada notifikasi.', style: Theme.of(context).textTheme.titleMedium),
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
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : unread 
                      ? AppColors.primary.withValues(alpha: 0.04) 
                      : (isDark ? AppColors.surfaceDark : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : unread 
                        ? AppColors.primary.withValues(alpha: 0.2) 
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ] : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => context.read<NotificationBloc>().add(ToggleNotificationSelectionRequested(notification.id)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: unread ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    unread ? Icons.notifications_active : Icons.notifications_none,
                    size: 18,
                    color: unread ? AppColors.primary : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        DateFormat('dd MMM, HH:mm').format(notification.createdAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread && !isSelectionMode)
                  Container(
                    margin: const EdgeInsets.only(top: 4, left: 8),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
