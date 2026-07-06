import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/ticket_q_brand.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.centered = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final align =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: align,
        children: [
          TweenAnimationBuilder<double>(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0.96, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: ((value - 0.96) / 0.04).clamp(0, 1).toDouble(),
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 80),
                  child: Transform.scale(
                    scale: value,
                    child: child,
                  ),
                ),
              );
            },
            child: Align(
              alignment: centered ? Alignment.center : Alignment.centerLeft,
              child: TicketQBrand(
                markSize: 54,
                showTagline: false,
                centered: centered,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
          if (eyebrow != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space12,
                vertical: AppDimensions.space8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.16),
                ),
              ),
              child: Text(
                eyebrow!,
                textAlign: textAlign,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space16),
          ],
          Text(
            title,
            textAlign: textAlign,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              subtitle,
              textAlign: textAlign,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
