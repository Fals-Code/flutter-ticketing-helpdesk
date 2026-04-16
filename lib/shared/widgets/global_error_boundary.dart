import 'package:flutter/material.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/shared/widgets/app_button.dart';

class GlobalErrorBoundary extends StatefulWidget {
  final Widget child;

  const GlobalErrorBoundary({super.key, required this.child});

  @override
  State<GlobalErrorBoundary> createState() => _GlobalErrorBoundaryState();
}

class _GlobalErrorBoundaryState extends State<GlobalErrorBoundary> {
  bool _hasError = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    // In actual Flutter 3.x, we might use ErrorWidget.builder globally in main.dart
    // but this boundary can also be used as a wrapper.
  }


  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _ErrorUI(
        error: _error?.toString() ?? 'An unexpected error occurred',
        onRetry: () => setState(() {
          _hasError = false;
          _error = null;
        }),
      );
    }

    return widget.child;
  }
}

class _ErrorUI extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorUI({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.priorityHigh.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.priorityHigh,
                size: 64,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Ups! Terjadi Kesalahan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aplikasi mengalami kendala teknis. Jangan khawatir, data Anda tetap aman.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Coba Lagi',
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
            ),
            const SizedBox(height: 24),
            Text(
              'Error Detail: $error',
              style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
