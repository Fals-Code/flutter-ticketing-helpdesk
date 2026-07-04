import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

enum AppSurfaceCardTone { standard, subdued, accent }

class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final AppSurfaceCardTone tone;
  final bool outlined;
  final VoidCallback? onTap;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.space16),
    this.tone = AppSurfaceCardTone.standard,
    this.outlined = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = switch (tone) {
      AppSurfaceCardTone.standard =>
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      AppSurfaceCardTone.subdued =>
        isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
      AppSurfaceCardTone.accent => AppColors.primary.withValues(
          alpha: isDark ? 0.18 : 0.08,
        ),
    };
    final borderColor = switch (tone) {
      AppSurfaceCardTone.accent => AppColors.primary.withValues(alpha: 0.22),
      _ => isDark ? AppColors.borderDark : AppColors.borderLight,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            border: outlined ? Border.all(color: borderColor) : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.brandNavyDeep
                    .withValues(alpha: isDark ? 0.16 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
