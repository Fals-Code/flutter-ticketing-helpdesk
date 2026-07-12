import 'package:flutter/material.dart';
import 'package:uts/shared/theme/extensions/app_radius.dart';
import 'package:uts/shared/theme/extensions/app_spacing.dart';

/// Responsive loading placeholder for the ticket-detail page.
///
/// The content remains scrollable when the viewport is shortened by the
/// keyboard, accessibility text scaling, split-screen mode, or a small device.
class TicketDetailSkeleton extends StatelessWidget {
  const TicketDetailSkeleton({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radius = context.radius;
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minimumContentHeight = constraints.maxHeight > spacing.xl * 2
              ? constraints.maxHeight - (spacing.xl * 2)
              : 0.0;

          return SingleChildScrollView(
            key: const Key('ticket-detail-skeleton-scroll-view'),
            padding: EdgeInsets.all(spacing.xl),
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minimumContentHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SkeletonBlock.circle(
                        size: spacing.xxl,
                        color: baseColor,
                      ),
                      const Spacer(),
                    ],
                  ),
                  SizedBox(height: spacing.xl),
                  _SkeletonBlock(
                    width: 120,
                    height: spacing.md,
                    color: baseColor,
                  ),
                  SizedBox(height: spacing.lg),
                  _SkeletonBlock(
                    width: double.infinity,
                    height: spacing.lg + spacing.xs,
                    color: baseColor,
                  ),
                  SizedBox(height: spacing.sm),
                  _SkeletonBlock(
                    width: 200,
                    height: spacing.lg + spacing.xs,
                    color: baseColor,
                  ),
                  SizedBox(height: spacing.xl - spacing.xs),
                  Row(
                    children: [
                      _SkeletonBlock(
                        width: 80,
                        height: spacing.lg,
                        color: baseColor,
                      ),
                      SizedBox(width: spacing.md),
                      _SkeletonBlock(
                        width: 60,
                        height: spacing.lg,
                        color: baseColor,
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.xl - spacing.xs),
                  Row(
                    children: [
                      _SkeletonBlock.circle(
                        size: spacing.xl + spacing.xs,
                        color: baseColor,
                      ),
                      SizedBox(width: spacing.md),
                      _SkeletonBlock(
                        width: 140,
                        height: spacing.md + 2,
                        color: baseColor,
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.xxl),
                  _SkeletonBlock(
                    width: double.infinity,
                    height: 100,
                    color: baseColor,
                    borderRadius: radius.card,
                  ),
                  SizedBox(height: spacing.xl),
                  _SkeletonBlock(
                    width: 80,
                    height: spacing.md,
                    color: baseColor,
                  ),
                  SizedBox(height: spacing.lg),
                  ...List.generate(
                    3,
                    (_) => Padding(
                      padding: EdgeInsets.only(bottom: spacing.lg),
                      child: Row(
                        children: [
                          _SkeletonBlock.circle(
                            size: spacing.md,
                            color: baseColor,
                          ),
                          SizedBox(width: spacing.lg - 2),
                          Expanded(
                            child: _SkeletonBlock(
                              height: spacing.md + 2,
                              color: baseColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    this.width,
    required this.height,
    required this.color,
    this.borderRadius = 0,
    this.isCircle = false,
  });

  const _SkeletonBlock.circle({required double size, required this.color})
    : width = size,
      height = size,
      borderRadius = 0,
      isCircle = true;

  final double? width;
  final double height;
  final Color color;
  final double borderRadius;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }
}
