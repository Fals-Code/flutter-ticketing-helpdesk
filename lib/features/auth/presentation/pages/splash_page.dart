import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/router/startup_gate.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/ticket_q_brand.dart';
import '../../presentation/bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.minimumRevealDuration = const Duration(milliseconds: 1500),
    this.reducedMotionRevealDuration = const Duration(milliseconds: 150),
    this.onMinimumRevealComplete,
  });

  final Duration minimumRevealDuration;
  final Duration reducedMotionRevealDuration;
  final VoidCallback? onMinimumRevealComplete;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _heroStageEnd = 0.30;
  static const _collapseStart = 0.23;
  static const _collapseEnd = 0.60;
  static const _compactStart = 0.50;
  static const _compactEnd = 0.83;
  static const _taglineStart = 0.70;

  late final AnimationController _entranceController;
  late final Animation<double> _contentOpacity;
  late final Animation<double> _contentScale;
  late final Animation<Offset> _contentSlide;

  bool _showProgress = false;
  bool _didStartSequence = false;
  Timer? _progressRevealTimer;
  Timer? _minimumRevealTimer;

  @visibleForTesting
  Duration get debugControllerDuration => _entranceController.duration!;

  @visibleForTesting
  bool get debugStartedAfterFirstFrame => _didStartSequence;

  @override
  void initState() {
    super.initState();
    _debugStartupLog('SplashPage initState');
    _entranceController = AnimationController(
      vsync: this,
      duration: widget.minimumRevealDuration,
    );
    _contentOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _contentScale = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _scheduleProgressReveal();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSequence();
    });
  }

  @override
  void dispose() {
    _progressRevealTimer?.cancel();
    _minimumRevealTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  void _scheduleProgressReveal() {
    _progressRevealTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final status = context.read<AuthBloc>().state.status;
      final isWaiting =
          status == AuthStatus.initial || status == AuthStatus.loading;
      if (isWaiting) {
        setState(() => _showProgress = true);
      }
    });
  }

  void _startSequence() {
    if (!mounted || _didStartSequence) return;
    _didStartSequence = true;

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      _entranceController.value = 1;
    } else {
      _entranceController.forward();
    }
    _debugStartupLog('Splash animation started');
    _scheduleMinimumReveal(disableAnimations: disableAnimations);
  }

  void _scheduleMinimumReveal({required bool disableAnimations}) {
    _minimumRevealTimer?.cancel();
    final revealDuration = disableAnimations
        ? widget.reducedMotionRevealDuration
        : widget.minimumRevealDuration;
    _minimumRevealTimer = Timer(revealDuration, () {
      if (!mounted) return;
      widget.onMinimumRevealComplete?.call();
      startupGate.markRevealComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final heroWordmarkStyle = theme.textTheme.displayLarge?.copyWith(
      color: colorScheme.onPrimary.withValues(alpha: 0.14),
      fontSize: 58,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    );
    final taglineStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final authStatus = context.select((AuthBloc bloc) => bloc.state.status);
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final showProgress = _showProgress &&
        (authStatus == AuthStatus.initial || authStatus == AuthStatus.loading);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth > 640
                  ? 520.0
                  : AppDimensions.formMaxWidth;
              final isShort = constraints.maxHeight < 620;
              final markSize = isShort ? 68.0 : 80.0;
              final heroMarkSize = isShort ? 92.0 : 112.0;
              final collapsedHeroExtent = isShort ? 168.0 : 196.0;
              final verticalPadding =
                  isShort ? AppDimensions.space20 : AppDimensions.space32;
              final heroBrand = RepaintBoundary(
                child: TicketQBrand(
                  axis: Axis.vertical,
                  markSize: heroMarkSize,
                  showTagline: false,
                  markBackground: colorScheme.primaryContainer,
                  wordmarkColor: colorScheme.onPrimary,
                ),
              );
              final compactBrand = RepaintBoundary(
                child: TicketQBrand(
                  markSize: markSize,
                  showTagline: false,
                  centered: true,
                ),
              );
              final taglineText = Text(
                AppStrings.appTagline,
                key: const ValueKey('splash-tagline-text'),
                textAlign: TextAlign.center,
                style: taglineStyle,
              );
              final progressChild = showProgress
                  ? Semantics(
                      key: const ValueKey('startup-progress'),
                      container: true,
                      liveRegion: true,
                      label: 'Status startup: Menyiapkan sesi aman Anda',
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: AppDimensions.space24,
                        ),
                        child: Column(
                          children: [
                            LoadingWidget(
                              size: 7,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(height: AppDimensions.space12),
                            Text(
                              'Menyiapkan sesi aman Anda...',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('idle-spacing'),
                      height: AppDimensions.space24,
                    );

              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: -80,
                    right: -40,
                    child: _AccentGlow(
                      size: constraints.maxWidth > 640 ? 220 : 156,
                      color: AppColors.brandCyan,
                    ),
                  ),
                  Positioned(
                    left: -60,
                    bottom: -90,
                    child: _AccentGlow(
                      size: constraints.maxWidth > 640 ? 260 : 188,
                      color: AppColors.brandIndigo,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _entranceController,
                    child: compactBrand,
                    builder: (context, child) {
                      final timeline =
                          disableAnimations ? 1.0 : _entranceController.value;
                      final collapseProgress = Curves.easeOutCubic.transform(
                        _interval(timeline, _collapseStart, _collapseEnd),
                      );
                      final heroOpacity =
                          1 - _interval(timeline, 0.28, _collapseEnd);
                      final heroScale =
                          _lerp(0.92, 1, _interval(timeline, 0, _heroStageEnd));
                      final heroWordmarkOpacity =
                          1 - _interval(timeline, _heroStageEnd * 0.35, 0.44);
                      final heroContainerWidth = _lerp(
                        constraints.maxWidth,
                        collapsedHeroExtent,
                        collapseProgress,
                      );
                      final heroContainerHeight = _lerp(
                        constraints.maxHeight,
                        collapsedHeroExtent,
                        collapseProgress,
                      );
                      final heroRadius = _lerp(
                        0,
                        AppDimensions.radiusXL,
                        collapseProgress,
                      );
                      final compactOpacity =
                          _interval(timeline, _compactStart, _compactEnd);
                      final brandSlide =
                          16 * (1 - _interval(timeline, _compactStart, 0.76));
                      final taglineOpacity =
                          _interval(timeline, _taglineStart, 1);
                      final taglineSlide = 10 * (1 - taglineOpacity);

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          IgnorePointer(
                            child: Opacity(
                              key: const ValueKey('splash-hero'),
                              opacity: heroOpacity,
                              child: Center(
                                child: Transform.scale(
                                  scale: heroScale,
                                  child: SizedBox(
                                    key:
                                        const ValueKey('splash-hero-container'),
                                    width: heroContainerWidth,
                                    height: heroContainerHeight,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius:
                                            BorderRadius.circular(heroRadius),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(heroRadius),
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppDimensions.space24,
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Opacity(
                                                  opacity: heroWordmarkOpacity,
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      AppStrings.appName,
                                                      maxLines: 1,
                                                      style: heroWordmarkStyle,
                                                    ),
                                                  ),
                                                ),
                                                heroBrand,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            child: Opacity(
                              key: const ValueKey('splash-compact'),
                              opacity: compactOpacity,
                              child: FadeTransition(
                                key: const ValueKey('splash-fade'),
                                opacity: _contentOpacity,
                                child: SlideTransition(
                                  position: _contentSlide,
                                  child: ScaleTransition(
                                    key: const ValueKey('splash-scale'),
                                    scale: _contentScale,
                                    child: _SplashCompactStage(
                                      maxWidth: maxWidth,
                                      minHeight: constraints.maxHeight,
                                      verticalPadding: verticalPadding,
                                      compactBrand: child!,
                                      brandSlide: brandSlide,
                                      taglineText: taglineText,
                                      taglineOpacity: taglineOpacity,
                                      taglineSlide: taglineSlide,
                                      progressChild: progressChild,
                                      disableAnimations: disableAnimations,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  double _interval(double value, double start, double end) {
    if (value <= start) return 0;
    if (value >= end) return 1;
    return (value - start) / (end - start);
  }

  double _lerp(double start, double end, double value) {
    return start + ((end - start) * value);
  }
}

class _SplashCompactStage extends StatelessWidget {
  const _SplashCompactStage({
    required this.maxWidth,
    required this.minHeight,
    required this.verticalPadding,
    required this.compactBrand,
    required this.brandSlide,
    required this.taglineText,
    required this.taglineOpacity,
    required this.taglineSlide,
    required this.progressChild,
    required this.disableAnimations,
  });

  final double maxWidth;
  final double minHeight;
  final double verticalPadding;
  final Widget compactBrand;
  final double brandSlide;
  final Widget taglineText;
  final double taglineOpacity;
  final double taglineSlide;
  final Widget progressChild;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.space24,
              vertical: verticalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  key: const ValueKey('splash-brand-stage'),
                  offset: Offset(0, brandSlide),
                  child: compactBrand,
                ),
                const SizedBox(height: AppDimensions.space12),
                Opacity(
                  key: const ValueKey('splash-tagline'),
                  opacity: taglineOpacity.clamp(0.0, 1.0).toDouble(),
                  alwaysIncludeSemantics: true,
                  child: Transform.translate(
                    offset: Offset(0, taglineSlide),
                    child: taglineText,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                AnimatedSwitcher(
                  duration: disableAnimations
                      ? Duration.zero
                      : const Duration(
                          milliseconds: AppDimensions.motionMediumMs,
                        ),
                  child: progressChild,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _debugStartupLog(String message) {
  assert(() {
    debugPrint(message);
    return true;
  }());
}

class _AccentGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _AccentGlow({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
