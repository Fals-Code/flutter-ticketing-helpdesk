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

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  double get _height {
    switch (widget.size) {
      case AppButtonSize.small:
        return AppDimensions.buttonHeightSM;
      case AppButtonSize.large:
        return AppDimensions.buttonHeightLG;
      case AppButtonSize.normal:
      default:
        return AppDimensions.buttonHeight;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case AppButtonSize.small:
        return 12;
      case AppButtonSize.large:
        return 16;
      case AppButtonSize.normal:
      default:
        return 14;
    }
  }

  BoxDecoration _getDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (widget.type) {
      case AppButtonType.primary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1), // Primary
              Color(0xFF4F46E5), // Slightly darker primary
            ],
          ),
          boxShadow: [
            if (!isDark && !_isDisabled)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        );
      case AppButtonType.secondary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(color: AppColors.primary, width: 1.5),
          color: _isHovered ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
        );
      case AppButtonType.ghost:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          color: _isHovered
              ? (isDark ? AppColors.surfaceDark2 : AppColors.backgroundLight)
              : Colors.transparent,
        );
      case AppButtonType.danger:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          color: AppColors.danger,
        );
    }
  }

  Color _getTextColor(BuildContext context) {
    switch (widget.type) {
      case AppButtonType.primary:
      case AppButtonType.danger:
        return AppColors.white;
      case AppButtonType.secondary:
      case AppButtonType.ghost:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _getTextColor(context);

    // Layout button content
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        else if (widget.icon != null) ...[
          Icon(widget.icon, size: _fontSize + 4, color: textColor),
          const SizedBox(width: AppDimensions.space8),
        ],
        if (!widget.isLoading || widget.icon == null) ...[
          if (widget.isLoading) const SizedBox(width: AppDimensions.space8),
          Flexible(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]
      ],
    );

    // Apply Opacity for disabled state
    Widget buttonWidget = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isDisabled ? 0.4 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
        decoration: _getDecoration(context),
        alignment: Alignment.center,
        child: content,
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: _isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _isDisabled ? null : (_) => _controller.forward(),
        onTapUp: _isDisabled
            ? null
            : (_) {
                _controller.reverse();
                widget.onPressed?.call();
              },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: buttonWidget,
        ),
      ),
    );
  }
}

