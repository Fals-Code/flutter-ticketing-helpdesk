import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'app_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      title: title ?? 'No Tickets Found',
      subtitle: subtitle ?? 'You don\'t have any active tickets right now. When you create one, it will appear here.',
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.emptyNotifications({String? title, String? subtitle, String? actionLabel, VoidCallback? onAction}) {
    return EmptyStateWidget(
      type: EmptyStateType.notifications,
      title: title ?? 'All Caught Up',
      subtitle: subtitle ?? 'You have no new notifications. We\'ll let you know when something important happens.',
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.emptySearch({String? title, String? subtitle, String? actionLabel, VoidCallback? onAction}) {
    return EmptyStateWidget(
      type: EmptyStateType.search,
      title: title ?? 'No Results Found',
      subtitle: subtitle ?? 'We couldn\'t find anything matching your search. Try adjusting your filters or keywords.',
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.emptyHistory({String? title, String? subtitle, String? actionLabel, VoidCallback? onAction}) {
    return EmptyStateWidget(
      type: EmptyStateType.history,
      title: title ?? 'No History Yet',
      subtitle: subtitle ?? 'Your activity history is currently empty. Start taking actions to see them recorded here.',
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
              AppButton.secondary(
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
    // Elegant SVG illustrations as strings (minimalist line art)
    String svgString;
    IconData fallbackIcon;
    Color iconColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    switch (type) {
      case EmptyStateType.tickets:
        svgString = '''<svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5V3H9v2"/><path d="M19 5H5a2 2 0 0 0-2 2v3a2 2 0 0 1 0 4v3a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-3a2 2 0 0 1 0-4V7a2 2 0 0 0-2-2z"/><path d="M9 13h6"/></svg>''';
        fallbackIcon = Icons.confirmation_number_outlined;
        break;
      case EmptyStateType.notifications:
        svgString = '''<svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/><line x1="2" y1="2" x2="22" y2="22"/></svg>''';
        fallbackIcon = Icons.notifications_off_outlined;
        break;
      case EmptyStateType.search:
        svgString = '''<svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/><line x1="11" y1="8" x2="11" y2="14"/><line x1="8" y1="11" x2="14" y2="11"/></svg>''';
        fallbackIcon = Icons.search_off_rounded;
        break;
      case EmptyStateType.history:
        svgString = '''<svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>''';
        fallbackIcon = Icons.history_rounded;
        break;
      case EmptyStateType.defaultState:
      default:
        svgString = '''<svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><line x1="9" y1="9" x2="15" y2="15"/><line x1="15" y1="9" x2="9" y2="15"/></svg>''';
        fallbackIcon = Icons.inbox_outlined;
        break;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : AppColors.borderLight.withValues(alpha: 0.5),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          // Subtle glow
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 32,
            spreadRadius: 8,
            offset: const Offset(0, 0),
          )
        ],
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Center(
        child: SvgPicture.string(
          svgString,
          width: 32,
          height: 32,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
      ),
    );
  }
}
