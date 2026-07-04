import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

enum AppStatusChipTone { neutral, info, success, warning, danger }

class AppStatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppStatusChipTone tone;

  const AppStatusChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = AppStatusChipTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final palette = switch (tone) {
      AppStatusChipTone.info => (AppColors.infoSoft, AppColors.info),
      AppStatusChipTone.success => (AppColors.successSoft, AppColors.success),
      AppStatusChipTone.warning => (AppColors.warningSoft, AppColors.warning),
      AppStatusChipTone.danger => (AppColors.dangerSoft, AppColors.danger),
      AppStatusChipTone.neutral => (
          Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark2
              : AppColors.surfaceLight2,
          Theme.of(context).brightness == Brightness.dark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
    };

    return Semantics(
      container: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space8,
        ),
        decoration: BoxDecoration(
          color: palette.$1,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: palette.$2.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppDimensions.iconSM, color: palette.$2),
              const SizedBox(width: AppDimensions.space8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.$2,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
