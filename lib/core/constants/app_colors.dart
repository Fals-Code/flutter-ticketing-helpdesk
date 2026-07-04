import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color brandNavy = Color(0xFF10233F);
  static const Color brandNavyDeep = Color(0xFF091426);
  static const Color brandNavySoft = Color(0xFF17345C);
  static const Color brandIndigo = Color(0xFF345CFF);
  static const Color brandIndigoSoft = Color(0xFFE5EBFF);
  static const Color brandCyan = Color(0xFF16B7D9);
  static const Color brandCyanSoft = Color(0xFFDDF7FC);

  static const Color primary = brandIndigo;
  static const Color accent = brandCyan;

  static const Color success = Color(0xFF169B6B);
  static const Color successSoft = Color(0xFFDBF5EA);
  static const Color warning = Color(0xFFE59A1A);
  static const Color warningSoft = Color(0xFFFFF1D9);
  static const Color danger = Color(0xFFD84D3F);
  static const Color dangerSoft = Color(0xFFFDE2DE);
  static const Color info = Color(0xFF2A83F7);
  static const Color infoSoft = Color(0xFFDDEBFF);

  static const Color backgroundLight = Color(0xFFF4F7FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLight2 = Color(0xFFEDF2F9);
  static const Color borderLight = Color(0xFFD7E0EC);
  static const Color textPrimaryLight = Color(0xFF10233F);
  static const Color textSecondaryLight = Color(0xFF5E718D);

  static const Color backgroundDark = Color(0xFF081221);
  static const Color surfaceDark = Color(0xFF0F1B30);
  static const Color surfaceDark2 = Color(0xFF17263E);
  static const Color borderDark = Color(0xFF283754);
  static const Color textPrimaryDark = Color(0xFFF3F7FC);
  static const Color textSecondaryDark = Color(0xFFA5B5CB);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Compatibility aliases for legacy aurora/splash surfaces.
  static const Color auroraIndigo = brandNavyDeep;
  static const Color auroraPurple = brandIndigo;
  static const Color auroraCyan = brandCyan;
  static const Color auroraRose = Color(0xFF4E89F5);

  static const Color statusOpen = info;
  static const Color statusInProgress = warning;
  static const Color statusResolved = success;
  static const Color priorityHigh = danger;
  static const Color priorityMedium = warning;
  static const Color priorityLow = success;
}
