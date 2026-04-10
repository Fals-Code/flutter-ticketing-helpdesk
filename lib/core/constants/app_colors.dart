import 'package:flutter/material.dart';

/// Palet warna utama aplikasi E-Ticketing Helpdesk.
/// Menggunakan tema biru-indigo profesional yang mendukung Dark & Light Mode.
abstract class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF5B6EF5);
  
  // ── Neutrals ───────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Light mode surfaces
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE8E8EC);
  static const Color textPrimaryLight = Color(0xFF111118);
  static const Color textSecondaryLight = Color(0xFF717180);

  // Dark mode surfaces
  static const Color backgroundDark = Color(0xFF0C0C0E);
  static const Color surfaceDark = Color(0xFF141416);
  static const Color borderDark = Color(0xFF232329);
  static const Color textPrimaryDark = Color(0xFFF0F0F5);
  static const Color textSecondaryDark = Color(0xFF7A7A8C);

  // ── Status colors ──────────────────────────────────────────────────────────
  static const Color statusOpen = Color(0xFF3B7BF8);
  static const Color statusInProgress = Color(0xFFF59B23);
  static const Color statusResolved = Color(0xFF22C55E);
  static const Color statusClosed = Color(0xFFA0A0B0);

  // ── Priority colors ────────────────────────────────────────────────────────
  static const Color priorityLow = Color(0xFF22C55E);
  static const Color priorityMedium = Color(0xFFF59B23);
  static const Color priorityHigh = Color(0xFFEF4444);
}

