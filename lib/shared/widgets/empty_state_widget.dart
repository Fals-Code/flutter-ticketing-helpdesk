import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'app_button.dart';

enum EmptyStateType {
  tickets,
  notifications,
  search,
  history,
  offline,
  confirmation,
  error,
  defaultState,
}

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

  factory EmptyStateWidget.emptyTickets({
    String? title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      type: EmptyStateType.tickets,
      title: title ?? 'Belum ada tiket',
      subtitle:
          subtitle ?? 'Buat laporan pertama untuk mulai menghubungi helpdesk.',
      actionLabel: actionLabel ?? 'Buat tiket',
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.emptyNotifications({
    String? title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      type: EmptyStateType.notifications,
      title: title ?? 'Tidak ada notifikasi baru',
      subtitle: subtitle ?? 'Update terbaru akan muncul di sini.',
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.emptySearch({
    String? title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      type: EmptyStateType.search,
      title: title ?? 'Hasil tidak ditemukan',
      subtitle: subtitle ?? 'Ubah kata kunci atau reset filter aktif.',
      actionLabel: actionLabel ?? 'Reset filter',
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.emptyHistory({
    String? title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      type: EmptyStateType.history,
      title: title ?? 'Riwayat masih kosong',
      subtitle: subtitle ?? 'Aktivitas ticketing akan muncul di halaman ini.',
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.offline({
    String? title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      type: EmptyStateType.offline,
      title: title ?? 'Anda sedang offline',
      subtitle: subtitle ?? 'Periksa koneksi lalu coba lagi.',
      actionLabel: actionLabel ?? 'Coba lagi',
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.confirmation({
    String? title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      type: EmptyStateType.confirmation,
      title: title ?? 'Perubahan tersimpan',
      subtitle: subtitle ?? 'Aksi Anda berhasil diproses.',
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.error({
    String? title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      type: EmptyStateType.error,
      title: title ?? 'Terjadi kendala',
      subtitle: subtitle ??
          'Data belum berhasil dimuat. Silakan coba beberapa saat lagi.',
      actionLabel: actionLabel ?? 'Muat ulang',
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppDimensions.formMaxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space48,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIllustration(isDark),
              const SizedBox(height: AppDimensions.space24),
              Text(
                title ?? 'Belum ada data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              Text(
                subtitle ?? 'Konten akan muncul ketika data sudah tersedia.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: secondaryText,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppDimensions.space24),
                type == EmptyStateType.search
                    ? AppButton.secondary(
                        label: actionLabel!,
                        onPressed: onAction,
                      )
                    : AppButton.primary(
                        label: actionLabel!,
                        onPressed: onAction,
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(bool isDark) {
    final config = switch (type) {
      EmptyStateType.tickets => (
          icon: Icons.confirmation_number_outlined,
          tone: AppColors.brandIndigo
        ),
      EmptyStateType.notifications => (
          icon: Icons.notifications_none_rounded,
          tone: AppColors.brandCyan
        ),
      EmptyStateType.search => (
          icon: Icons.manage_search_rounded,
          tone: AppColors.info
        ),
      EmptyStateType.history => (
          icon: Icons.timeline_rounded,
          tone: AppColors.brandIndigo
        ),
      EmptyStateType.offline => (
          icon: Icons.wifi_off_rounded,
          tone: AppColors.warning
        ),
      EmptyStateType.confirmation => (
          icon: Icons.check_circle_outline_rounded,
          tone: AppColors.success
        ),
      EmptyStateType.error => (
          icon: Icons.error_outline_rounded,
          tone: AppColors.danger
        ),
      EmptyStateType.defaultState => (
          icon: Icons.inbox_outlined,
          tone: AppColors.brandIndigo
        ),
    };

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            config.tone.withValues(alpha: isDark ? 0.22 : 0.16),
            AppColors.brandNavy.withValues(alpha: isDark ? 0.26 : 0.08),
          ],
        ),
        border: Border.all(
          color: config.tone.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.brandNavyDeep.withValues(alpha: isDark ? 0.26 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        config.icon,
        size: 36,
        color: config.tone,
      ),
    );
  }
}
