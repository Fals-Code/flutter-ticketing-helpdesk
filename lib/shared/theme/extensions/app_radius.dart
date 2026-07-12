import 'package:flutter/material.dart';

/// Global corner-radius tokens for interactive and surface components.
@immutable
class AppRadius extends ThemeExtension<AppRadius> {
  const AppRadius({
    this.field = 8,
    this.button = 8,
    this.card = 12,
    this.sheet = 16,
    this.dialog = 24,
  });

  final double field;
  final double button;
  final double card;
  final double sheet;
  final double dialog;

  @override
  AppRadius copyWith({
    double? field,
    double? button,
    double? card,
    double? sheet,
    double? dialog,
  }) {
    return AppRadius(
      field: field ?? this.field,
      button: button ?? this.button,
      card: card ?? this.card,
      sheet: sheet ?? this.sheet,
      dialog: dialog ?? this.dialog,
    );
  }

  @override
  AppRadius lerp(covariant AppRadius? other, double t) {
    if (other == null) return this;

    return AppRadius(
      field: field + (other.field - field) * t,
      button: button + (other.button - button) * t,
      card: card + (other.card - card) * t,
      sheet: sheet + (other.sheet - sheet) * t,
      dialog: dialog + (other.dialog - dialog) * t,
    );
  }
}

/// Provides theme radius tokens with safe defaults when no extension exists.
extension AppRadiusBuildContext on BuildContext {
  AppRadius get radius =>
      Theme.of(this).extension<AppRadius>() ?? const AppRadius();
}
