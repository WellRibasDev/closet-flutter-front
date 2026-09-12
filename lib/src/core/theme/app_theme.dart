import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import 'app_colors.dart';

/// Tema Material (forms/scaffold) + tema shadcn (botões/cards/chips).
abstract final class AppTheme {
  static ThemeData get material {
    final baseText = GoogleFonts.nunitoTextTheme();
    final display = GoogleFonts.playfairDisplayTextTheme();

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.rose,
      primary: AppColors.roseDeep,
      onPrimary: Colors.white,
      secondary: AppColors.lilac,
      onSecondary: AppColors.purpleInk,
      tertiary: AppColors.butter,
      onTertiary: AppColors.yellowInk,
      surface: AppColors.cream,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.blush,
      textTheme: baseText
          .copyWith(
            headlineMedium: display.headlineMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
            headlineSmall: display.headlineSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
            titleLarge: baseText.titleLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          )
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.roseDeep,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card.withValues(alpha: 0.95),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.petal.withValues(alpha: 0.7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.petal.withValues(alpha: 0.55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.roseDeep, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: GoogleFonts.nunito(color: AppColors.inkSoft),
        hintStyle: GoogleFonts.nunito(color: AppColors.inkSoft),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.roseDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.roseDeep,
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.nunito(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.roseDeep,
      ),
    );
  }

  static shadcn.ThemeData get shadcnTheme {
    return const shadcn.ThemeData(
      colorScheme: elisaPastel,
      radius: 1.0,
      scaling: 1.0,
      surfaceOpacity: 0.92,
      surfaceBlur: 12,
    );
  }

  static const shadcn.ColorScheme elisaPastel = shadcn.ColorScheme(
    brightness: Brightness.light,
    background: AppColors.blush,
    foreground: AppColors.ink,
    card: AppColors.card,
    cardForeground: AppColors.ink,
    popover: AppColors.cream,
    popoverForeground: AppColors.ink,
    primary: AppColors.roseDeep,
    primaryForeground: Color(0xFFFFFFFF),
    secondary: AppColors.lilac,
    secondaryForeground: AppColors.purpleInk,
    muted: AppColors.blushDeep,
    mutedForeground: AppColors.inkSoft,
    accent: AppColors.apricot,
    accentForeground: AppColors.orangeInk,
    destructive: AppColors.danger,
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFFF0C8D8),
    input: Color(0xFFF0C8D8),
    ring: AppColors.rose,
    chart1: AppColors.roseDeep,
    chart2: AppColors.lilacDeep,
    chart3: AppColors.butterDeep,
    chart4: AppColors.apricotDeep,
    chart5: AppColors.rose,
  );
}
