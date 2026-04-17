import 'package:flutter/services.dart';

class HapticHelper {
  static Future<void> light() async => HapticFeedback.lightImpact();
  static Future<void> medium() async => HapticFeedback.mediumImpact();
  static Future<void> heavy() async => HapticFeedback.heavyImpact();
  static Future<void> selection() async => HapticFeedback.selectionClick();
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }
}
