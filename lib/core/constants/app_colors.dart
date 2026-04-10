import 'package:flutter/material.dart';

/// Palet warna utama aplikasi E-Ticketing Helpdesk.
/// Menggunakan tema biru-indigo profesional yang mendukung Dark & Light Mode.
abstract class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF4F71FF);
  static const Color primaryLight = Color(0xFF7B96FF);
  static const Color primaryDark = Color(0xFF2B4ECC);

  static const Color secondary = Color(0xFF00C9A7);
  static const Color secondaryLight = Color(0xFF4DDFCC);
  static const Color secondaryDark = Color(0xFF009A81);

  // ── Neutrals ───────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0A0D14);

  // Light mode surfaces
  static const Color surfaceLight = Color(0xFFF5F7FF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF1A202C);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Dark mode surfaces
  static const Color surfaceDark = Color(0xFF0E1117);
  static const Color cardDark = Color(0xFF171C28);
  static const Color borderDark = Color(0xFF2D3748);
  static const Color textPrimaryDark = Color(0xFFF0F4FF);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // ── Status colors ──────────────────────────────────────────────────────────
  static const Color statusOpen = Color(0xFF4F71FF);
  static const Color statusInProgress = Color(0xFFF59E0B);
  static const Color statusResolved = Color(0xFF10B981);
  static const Color statusClosed = Color(0xFF6B7280);
  static const Color statusCritical = Color(0xFFEF4444);

  // ── Priority colors ────────────────────────────────────────────────────────
  static const Color priorityLow = Color(0xFF10B981);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityCritical = Color(0xFF7C3AED);

  // ── Gradient definitions ───────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF7B5FF9)],
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E1117), Color(0xFF151B2E)],
  );
}
