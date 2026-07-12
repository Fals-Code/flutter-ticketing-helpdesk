import 'package:flutter/material.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/shared/theme/extensions/app_motion.dart';
import 'package:uts/shared/theme/extensions/app_spacing.dart';

/// Pure presentation shell for the ticket-list search and filter controls.
///
/// Business state and callbacks stay in [TicketListPage]. This widget only
/// owns layout, responsive height, spacing, and the optional-section motion.
class TicketListFilterHeader extends StatelessWidget {
  const TicketListFilterHeader({
    super.key,
    required this.isDark,
    required this.searchField,
    required this.filterButton,
    required this.statusChips,
    this.assigneeFilterButton,
    this.activeAssigneeChip,
  });

  static const double _compactHeightFactor = 3.375;
  static const double _expandedHeightFactor = 4.5;

  final bool isDark;
  final Widget searchField;
  final Widget filterButton;
  final Widget? assigneeFilterButton;
  final Widget? activeAssigneeChip;
  final List<Widget> statusChips;

  /// Predictable height for use by [PreferredSize] while still allowing a
  /// modest text-scaling allowance on accessibility configurations.
  static double preferredHeight(
    BuildContext context, {
    required bool expanded,
  }) {
    final spacing = context.spacing;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final scaleDelta = (textScale - 1).clamp(0.0, 0.5).toDouble();
    final accessibilityAllowance = scaleDelta * spacing.xl;

    return spacing.xxl *
            (expanded ? _expandedHeightFactor : _compactHeightFactor) +
        accessibilityAllowance;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final motion = context.motion;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final scaleDelta = (textScale - 1).clamp(0.0, 0.5).toDouble();
    final statusRowHeight = 36 + (scaleDelta * spacing.xl);

    return ColoredBox(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: searchField),
                SizedBox(width: spacing.sm),
                filterButton,
                if (assigneeFilterButton != null) ...[
                  SizedBox(width: spacing.sm),
                  assigneeFilterButton!,
                ],
              ],
            ),
            SizedBox(height: spacing.md),
            AnimatedSize(
              duration: motion.transition,
              curve: motion.standardCurve,
              alignment: Alignment.topCenter,
              child: activeAssigneeChip ?? const SizedBox.shrink(),
            ),
            SizedBox(
              height: statusRowHeight,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                children: statusChips,
              ),
            ),
            SizedBox(height: spacing.sm),
          ],
        ),
      ),
    );
  }
}
