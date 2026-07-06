import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import 'ticket_q_mark.dart';

class TicketQBrand extends StatelessWidget {
  const TicketQBrand({
    this.markSize = 64,
    this.axis = Axis.horizontal,
    this.showTagline = false,
    this.centered = true,
    this.markBackground,
    this.wordmarkColor,
    this.taglineColor,
    this.wordmarkStyle,
    this.taglineStyle,
    super.key,
  });

  final double markSize;
  final Axis axis;
  final bool showTagline;
  final bool centered;
  final Color? markBackground;
  final Color? wordmarkColor;
  final Color? taglineColor;
  final TextStyle? wordmarkStyle;
  final TextStyle? taglineStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mark = Container(
      width: markSize,
      height: markSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: markBackground ?? colorScheme.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TicketQMark(
        size: markSize * 0.82,
        elevated: false,
      ),
    );
    final wordmark = Flexible(
      child: Text(
        AppStrings.appName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: (wordmarkStyle ?? theme.textTheme.titleLarge)?.copyWith(
          color: wordmarkColor ?? colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
    final tagline = Text(
      AppStrings.appTagline,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: (taglineStyle ?? theme.textTheme.bodyMedium)?.copyWith(
        color: taglineColor ?? colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );

    return Semantics(
      container: true,
      label: showTagline
          ? '${AppStrings.appName}. ${AppStrings.appTagline}'
          : AppStrings.appName,
      child: axis == Axis.vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                mark,
                const SizedBox(height: AppDimensions.space16),
                Text(
                  AppStrings.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: centered ? TextAlign.center : TextAlign.start,
                  style: (wordmarkStyle ?? theme.textTheme.displayLarge)
                      ?.copyWith(
                    color: wordmarkColor ?? colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                if (showTagline) ...[
                  const SizedBox(height: AppDimensions.space8),
                  tagline,
                ],
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment:
                      centered ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    mark,
                    const SizedBox(width: AppDimensions.space12),
                    wordmark,
                  ],
                ),
                if (showTagline) ...[
                  const SizedBox(height: AppDimensions.space12),
                  tagline,
                ],
              ],
            ),
    );
  }
}
