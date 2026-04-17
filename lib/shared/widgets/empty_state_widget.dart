import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'app_button.dart';

enum EmptyStateType { tickets, notifications, search, history, defaultState }

/// Widget empty state yang modern dengan gaya desain Linear/Raycast.
/// Menampilkan ilustrasi SVG/Icon dengan efek subtle glow/glassmorphism,
/// judul, deskripsi, dan tombol aksi opsional.
class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    this.type = EmptyStateType.defaultState,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  factory EmptyStateWidget.emptyTickets({String? title, String? subtitle, String? actionLabel, VoidCallback? onAction}) {
    return EmptyStateWidget(
      type: EmptyStateType.tickets,
      title: title ?? 'Belum Ada Laporan',
      subtitle: subtitle ?? 'Buat tiket pertamamu untuk mendapat bantuan dari tim helpdesk kami.',
      actionLabel: actionLabel ?? 'Buat Tiket Sekarang',
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.emptyNotifications({String? title, String? subtitle, String? actionLabel, VoidCallback? onAction}) {
    return EmptyStateWidget(
      type: EmptyStateType.notifications,
      title: title ?? 'Semua Beres',
      subtitle: subtitle ?? 'Anda tidak memiliki notifikasi baru.',
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.emptySearch({String? title, String? subtitle, String? actionLabel, VoidCallback? onAction}) {
    return EmptyStateWidget(
      type: EmptyStateType.search,
      title: title ?? 'Tidak Ditemukan',
      subtitle: subtitle ?? 'Coba kata kunci atau filter yang berbeda.',
      actionLabel: actionLabel ?? 'Hapus Filter',
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.emptyHistory({String? title, String? subtitle, String? actionLabel, VoidCallback? onAction}) {
    return EmptyStateWidget(
      type: EmptyStateType.history,
      title: title ?? 'Belum Ada Riwayat',
      subtitle: subtitle ?? 'Riwayat aktivitas Anda masih kosong.',
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space32, vertical: AppDimensions.space64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIllustration(isDark),
            const SizedBox(height: AppDimensions.space24),
            Text(
              title ?? 'Nothing to see here',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              subtitle ?? 'There is no data available to display at this time.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.space24),
              type == EmptyStateType.search 
               ? AppButton.ghost(
                  label: actionLabel!,
                  onPressed: onAction,
                  size: AppButtonSize.normal,
                )
               : AppButton.primary(
                  label: actionLabel!,
                  onPressed: onAction,
                  size: AppButtonSize.normal,
                ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(bool isDark) {
    IconData fallbackIcon;

    switch (type) {
      case EmptyStateType.tickets:
        fallbackIcon = Icons.inbox_outlined;
        break;
      case EmptyStateType.notifications:
        fallbackIcon = Icons.notifications_off_outlined;
        break;
      case EmptyStateType.search:
        fallbackIcon = Icons.manage_search_rounded;
        break;
      case EmptyStateType.history:
        fallbackIcon = Icons.history_rounded;
        break;
      case EmptyStateType.defaultState:
        fallbackIcon = Icons.inbox_outlined;
        break;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.accent.withValues(alpha: 0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : AppColors.borderLight.withValues(alpha: 0.5),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 32,
            spreadRadius: 8,
            offset: const Offset(0, 0),
          )
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: 36,
          color: AppColors.primary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
