import 'package:flutter/material.dart';

/// Palet warna utama aplikasi E-Ticketing Helpdesk.
/// Menggunakan tema dark-first, clean, dan profesional.
abstract class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6366F1); // Indigo vibrant
  static const Color accent = Color(0xFF8B5CF6); // Purple

  // ── Status & Feedback ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // ── Aurora Palette (Redesign) ──────────────────────────────────────────────
  static const Color auroraIndigo = Color(0xFF1E1B4B);
  static const Color auroraPurple = Color(0xFF6366F1);
  static const Color auroraCyan = Color(0xFF06B6D4);
  static const Color auroraRose = Color(0xFFF43F5E);

  // ── Dark Theme Surfaces ────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0A0A0F); // Near black
  static const Color surfaceDark = Color(0xFF111118); // Card bg
  static const Color surfaceDark2 = Color(0xFF1A1A24); // Elevated
  static const Color borderDark = Color(0xFF2A2A35);
  static const Color textPrimaryDark = Color(0xFFF1F1F5);
  static const Color textSecondaryDark = Color(0xFF71717A);

  // ── Light Theme Surfaces ───────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE4E4E7);
  static const Color textPrimaryLight = Color(0xFF09090B);
  static const Color textSecondaryLight = Color(0xFF71717A);

  // ── Neutrals/Common ────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ── Legacy Compatibility / Ticket Status ───────────────────────────────────
  static const Color statusOpen = primary;
  static const Color statusInProgress = warning;
  static const Color statusResolved = success;
  static const Color priorityHigh = danger;
  static const Color priorityMedium = warning;
  static const Color priorityLow = success;
}
