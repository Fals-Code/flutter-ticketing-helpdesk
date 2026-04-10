import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key untuk menyimpan preferensi tema di SharedPreferences.
const _themeKey = 'theme_mode';

/// [ThemeCubit] mengelola state ThemeMode (light/dark/system)
/// dan mempersistnya ke SharedPreferences agar tetap tersimpan
/// saat aplikasi dibuka ulang.
class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences preferences;

  ThemeCubit({required this.preferences})
      : super(_loadInitialTheme(preferences));

  /// Memuat theme terakhir yang dipilih pengguna dari storage.
  static ThemeMode _loadInitialTheme(SharedPreferences prefs) {
    final saved = prefs.getString(_themeKey);
    switch (saved) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  /// Toggle antara light dan dark mode.
  /// Jika saat ini system/light → switch ke dark, sebaliknya ke light.
  void toggleTheme() {
    final isDark = state == ThemeMode.dark;
    setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  /// Set tema secara eksplisit dan simpan ke storage.
  void setTheme(ThemeMode mode) {
    emit(mode);
    preferences.setString(_themeKey, _modeToString(mode));
  }

  /// Reset ke tema sistem.
  void resetToSystem() => setTheme(ThemeMode.system);

  String _modeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Helper: apakah saat ini dalam mode gelap?
  bool get isDark => state == ThemeMode.dark;
}
