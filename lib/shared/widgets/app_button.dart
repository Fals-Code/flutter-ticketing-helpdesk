import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

enum AppButtonType { primary, secondary, ghost, danger }

enum AppButtonSize { small, normal, large }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final AppButtonType type;
  final AppButtonSize size;

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.size = AppButtonSize.normal,
  }) : type = AppButtonType.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.size = AppButtonSize.normal,
  }) : type = AppButtonType.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.size = AppButtonSize.normal,
  }) : type = AppButtonType.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.size = AppButtonSize.normal,
  }) : type = AppButtonType.danger;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppDimensions.motionFastMs),
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.985,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  double get _height => switch (widget.size) {
        AppButtonSize.small => AppDimensions.buttonHeightSM,
        AppButtonSize.large => AppDimensions.buttonHeightLG,
        AppButtonSize.normal => AppDimensions.buttonHeight,
      };

  double get _fontSize => switch (widget.size) {
        AppButtonSize.small => 12,
        AppButtonSize.large => 16,
        AppButtonSize.normal => 14,
      };

  BoxDecoration _decoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(AppDimensions.radiusSM);

    switch (widget.type) {
      case AppButtonType.primary:
        return BoxDecoration(
          color: _isDisabled ? AppColors.borderLight : AppColors.primary,
          borderRadius: borderRadius,
          boxShadow: _isDisabled
              ? const []
              : [
                  BoxShadow(
                    color: AppColors.brandNavyDeep.withValues(
                      alpha: isDark ? 0.28 : 0.16,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        );
      case AppButtonType.secondary:
        return BoxDecoration(
          color: _isHovered
              ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08)
              : (isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight),
          borderRadius: borderRadius,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        );
      case AppButtonType.ghost:
        return BoxDecoration(
          color: _isHovered
              ? (isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2)
              : Colors.transparent,
          borderRadius: borderRadius,
        );
      case AppButtonType.danger:
        return BoxDecoration(
          color: _isDisabled ? AppColors.borderLight : AppColors.danger,
          borderRadius: borderRadius,
          boxShadow: _isDisabled
              ? const []
              : [
                  BoxShadow(
                    color: AppColors.danger.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
        );
    }
  }

  Color _textColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isDisabled) {
      return isDark
          ? AppColors.textSecondaryDark
          : AppColors.textSecondaryLight;
    }

    return switch (widget.type) {
      AppButtonType.primary || AppButtonType.danger => AppColors.white,
      AppButtonType.secondary || AppButtonType.ghost => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _textColor(context);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        else if (widget.icon != null) ...[
          Icon(widget.icon, size: _fontSize + 4, color: textColor),
          const SizedBox(width: AppDimensions.space8),
        ],
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.2,
            ),
          ),
        ),
      ],
    );

    final child = AnimatedOpacity(
      duration: const Duration(milliseconds: AppDimensions.motionFastMs),
      opacity: _isDisabled ? 0.72 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: AppDimensions.motionFastMs),
        width: widget.width,
        constraints: const BoxConstraints(minWidth: 64),
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
        alignment: Alignment.center,
        decoration: _decoration(context),
        child: content,
      ),
    );

    return Semantics(
      button: true,
      enabled: !_isDisabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: _isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: _isDisabled ? null : (_) => _controller.forward(),
          onTapUp: _isDisabled
              ? null
              : (_) {
                  _controller.reverse();
                  widget.onPressed?.call();
                },
          onTapCancel: _controller.reverse,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: child,
          ),
        ),
      ),
    );
  }
}
