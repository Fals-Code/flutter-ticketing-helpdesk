import 'package:flutter/material.dart';

import 'app_text_field.dart';

class AppPasswordField extends StatelessWidget {
  const AppPasswordField({
    required this.label,
    required this.controller,
    this.hint,
    this.focusNode,
    this.validator,
    this.onSubmitted,
    this.textInputAction = TextInputAction.done,
    this.prefixIcon = Icons.lock_outline,
    this.enabled = true,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final TextInputAction textInputAction;
  final IconData prefixIcon;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: hint,
      controller: controller,
      focusNode: focusNode,
      isPassword: true,
      prefixIcon: prefixIcon,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      validator: validator,
      enabled: enabled,
      semanticLabel: semanticLabel,
    );
  }
}
