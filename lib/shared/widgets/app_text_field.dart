import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Text field kustom yang konsisten dengan design system aplikasi.
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
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
  final double borderRadius;
  final void Function(String)? onSubmitted;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
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
    this.borderRadius = 8,
    this.onSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _isFocused
                ? AppColors.primary
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
        const SizedBox(height: 8),

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
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.hint,
              fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFFAFAFA),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 20, // Slightly increased from 18 for better visual
                      color: _isFocused
                          ? AppColors.primary
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    )
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    )
                  : widget.suffixWidget,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

