import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark ? _darkColorScheme : _lightColorScheme;
    final textTheme = _buildTextTheme(
      colorScheme.onSurface,
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      canvasColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: AppDimensions.iconLG,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: AppDimensions.elevationSM,
        shadowColor: AppColors.brandNavyDeep.withValues(alpha: 0.10),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppDimensions.elevationSM,
          shadowColor: AppColors.brandNavyDeep.withValues(alpha: 0.18),
          foregroundColor: AppColors.white,
          backgroundColor: colorScheme.primary,
          disabledForegroundColor:
              colorScheme.onSurface.withValues(alpha: 0.42),
          disabledBackgroundColor:
              colorScheme.onSurface.withValues(alpha: 0.12),
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space20,
            vertical: AppDimensions.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space20,
            vertical: AppDimensions.space12,
          ),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: _buildInputTheme(isDark),
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.08),
        selectedColor: colorScheme.primary.withValues(alpha: 0.14),
        secondarySelectedColor: colorScheme.secondary.withValues(alpha: 0.14),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space8,
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
        shadowColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? colorScheme.primary
              : (isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight);
          return textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
            size: AppDimensions.iconLG,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.surfaceDark2 : AppColors.brandNavy,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        barrierColor: AppColors.brandNavyDeep.withValues(alpha: 0.62),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor:
            isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
        showDragHandle: true,
        dragHandleColor: (isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight)
            .withValues(alpha: 0.48),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLG),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }

  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -0.8,
        color: primaryColor,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.16,
        letterSpacing: -0.6,
        color: primaryColor,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: primaryColor,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.24,
        letterSpacing: -0.3,
        color: primaryColor,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.24,
        color: primaryColor,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: primaryColor,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: primaryColor,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: primaryColor,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: primaryColor,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: secondaryColor,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: primaryColor,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: secondaryColor,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: secondaryColor,
      ),
    );
  }

  static InputDecorationTheme _buildInputTheme(bool isDark) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final fillColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space14,
      ),
      hintStyle: TextStyle(
        color: secondaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      helperStyle: TextStyle(
        color: secondaryColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: const TextStyle(
        color: AppColors.danger,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      border: border(borderColor),
      enabledBorder: border(borderColor),
      focusedBorder: border(AppColors.primary, width: 1.6),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, width: 1.6),
    );
  }

  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brandIndigo,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.brandIndigo,
    onPrimary: AppColors.white,
    secondary: AppColors.brandCyan,
    onSecondary: AppColors.white,
    error: AppColors.danger,
    onError: AppColors.white,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    outline: AppColors.borderLight,
  );

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brandIndigo,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.brandIndigo,
    onPrimary: AppColors.white,
    secondary: AppColors.brandCyan,
    onSecondary: AppColors.white,
    error: AppColors.danger,
    onError: AppColors.white,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
    outline: AppColors.borderDark,
  );
}
