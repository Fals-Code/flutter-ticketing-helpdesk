import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Text field kustom yang konsisten dengan design system aplikasi terbaru.
/// Menggunakan style clean dengan label di atas input field.
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final bool enabled;
  final int maxLines;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;
  final bool isSuccess;
  final int? maxLength;
  final int? minLines;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixWidget,
    this.enabled = true,
    this.maxLines = 1,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.isSuccess = false,
    this.maxLength,
    this.minLines,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Label (Not floating)
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _isFocused ? AppColors.primary : primaryTextColor,
          ),
        ),
        const SizedBox(height: AppDimensions.space8),

        // Input field
        Focus(
          onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            onChanged: widget.onChanged,
            enabled: widget.enabled,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            style: TextStyle(fontSize: 14, color: primaryTextColor),
            decoration: InputDecoration(
              hintText: widget.hint,
              helperText: widget.helperText,
              helperMaxLines: 2,
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12),
                      child: Icon(
                        widget.prefixIcon,
                        size: AppDimensions.iconMD,
                        color: _isFocused ? AppColors.primary : secondaryTextColor,
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 24,
              ),
              suffixIcon: _buildSuffixIcon(isDark, secondaryTextColor),
              // Success border adjustments
              enabledBorder: widget.isSuccess
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      borderSide: const BorderSide(color: AppColors.success, width: 1.5),
                    )
                  : null,
              focusedBorder: widget.isSuccess
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      borderSide: const BorderSide(color: AppColors.success, width: 2),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon(bool isDark, Color secondaryColor) {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: AppDimensions.iconMD,
          color: secondaryColor,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
        splashRadius: 20,
      );
    }

    if (widget.isSuccess) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.space12),
        child: Icon(
          Icons.check_circle_outline,
          size: AppDimensions.iconMD,
          color: AppColors.success,
        ),
      );
    }

    return widget.suffixWidget;
  }
}
