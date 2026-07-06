import 'package:flutter/material.dart';

import 'app_button.dart';

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppButton.primary(
        label: label,
        onPressed: onPressed,
        isLoading: isLoading,
        icon: icon,
        size: AppButtonSize.large,
      ),
    );
  }
}
