import 'package:flutter/material.dart';

/// Global motion tokens for interaction, component, and page transitions.
@immutable
class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({
    this.fast = const Duration(milliseconds: 180),
    this.transition = const Duration(milliseconds: 300),
    this.page = const Duration(milliseconds: 400),
    this.standardCurve = Curves.easeOutCubic,
  });

  final Duration fast;
  final Duration transition;
  final Duration page;
  final Curve standardCurve;

  @override
  AppMotion copyWith({
    Duration? fast,
    Duration? transition,
    Duration? page,
    Curve? standardCurve,
  }) {
    return AppMotion(
      fast: fast ?? this.fast,
      transition: transition ?? this.transition,
      page: page ?? this.page,
      standardCurve: standardCurve ?? this.standardCurve,
    );
  }

  @override
  AppMotion lerp(covariant AppMotion? other, double t) {
    if (other == null) return this;

    return AppMotion(
      fast: _lerpDuration(fast, other.fast, t),
      transition: _lerpDuration(transition, other.transition, t),
      page: _lerpDuration(page, other.page, t),
      standardCurve: t < 0.5 ? standardCurve : other.standardCurve,
    );
  }

  static Duration _lerpDuration(Duration begin, Duration end, double t) {
    return Duration(
      microseconds: (begin.inMicroseconds +
              (end.inMicroseconds - begin.inMicroseconds) * t)
          .round(),
    );
  }
}

/// Provides theme motion tokens with safe defaults when no extension exists.
extension AppMotionBuildContext on BuildContext {
  AppMotion get motion =>
      Theme.of(this).extension<AppMotion>() ?? const AppMotion();
}
