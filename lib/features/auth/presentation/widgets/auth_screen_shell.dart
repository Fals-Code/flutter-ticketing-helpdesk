import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    required this.header,
    required this.form,
    this.footer,
    this.showBackButton = false,
    this.onBack,
    super.key,
  });

  final Widget header;
  final Widget form;
  final Widget? footer;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark
                  ? AppColors.backgroundDark
                  : AppColors.brandIndigoSoft.withValues(alpha: 0.55),
              isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final maxWidth = isWide ? 1120.0 : 520.0;
              final content = isWide
                  ? _WideAuthLayout(
                      header: header,
                      form: form,
                      footer: footer,
                    )
                  : _CompactAuthLayout(
                      header: header,
                      form: form,
                      footer: footer,
                    );

              final contentPadding = EdgeInsets.fromLTRB(
                constraints.maxWidth >= 600
                    ? AppDimensions.space32
                    : AppDimensions.space20,
                AppDimensions.space16,
                constraints.maxWidth >= 600
                    ? AppDimensions.space32
                    : AppDimensions.space20,
                AppDimensions.space24,
              );

              return Stack(
                fit: StackFit.expand,
                children: [
                  const _BackgroundAccent(
                    alignment: Alignment.topRight,
                    color: AppColors.brandCyan,
                    size: 240,
                    opacity: 0.14,
                  ),
                  const _BackgroundAccent(
                    alignment: Alignment.bottomLeft,
                    color: AppColors.brandIndigo,
                    size: 320,
                    opacity: 0.1,
                  ),
                  AnimatedPadding(
                    duration: disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.only(bottom: viewInsets.bottom),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: contentPadding,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                constraints.maxHeight - contentPadding.vertical,
                            maxWidth: maxWidth,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showBackButton)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppDimensions.space16,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: onBack ??
                                          () =>
                                              Navigator.of(context).maybePop(),
                                      icon:
                                          const Icon(Icons.arrow_back_rounded),
                                      label: const Text('Kembali'),
                                    ),
                                  ),
                                ),
                              TweenAnimationBuilder<double>(
                                duration: disableAnimations
                                    ? Duration.zero
                                    : const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                tween: Tween<double>(begin: 0.96, end: 1),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: disableAnimations
                                        ? 1
                                        : ((value - 0.96) / 0.04).clamp(0, 1),
                                    child: Transform.scale(
                                      scale: value,
                                      alignment: Alignment.topCenter,
                                      child: child,
                                    ),
                                  );
                                },
                                child: content,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CompactAuthLayout extends StatelessWidget {
  const _CompactAuthLayout({
    required this.header,
    required this.form,
    this.footer,
  });

  final Widget header;
  final Widget form;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: AppDimensions.space24),
        form,
        if (footer != null) ...[
          const SizedBox(height: AppDimensions.space20),
          footer!,
        ],
      ],
    );
  }
}

class _WideAuthLayout extends StatelessWidget {
  const _WideAuthLayout({
    required this.header,
    required this.form,
    this.footer,
  });

  final Widget header;
  final Widget form;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppDimensions.space32),
            child: header,
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              form,
              if (footer != null) ...[
                const SizedBox(height: AppDimensions.space20),
                footer!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BackgroundAccent extends StatelessWidget {
  const _BackgroundAccent({
    required this.alignment,
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Alignment alignment;
  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
