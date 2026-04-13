import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand colors ─────────────────────────────────────────────
  static const Color primary     = Color(0xFF6C63FF);   // Electric Violet
  static const Color primaryDark = Color(0xFF4C46C9);
  static const Color accent      = Color(0xFF00E5CC);   // Cyan teal
  static const Color danger      = Color(0xFFFF4F6D);   // Alert red
  static const Color warning     = Color(0xFFFFB347);   // Orange
  static const Color success     = Color(0xFF4CAF50);   // Green

  // ── Surface shades ────────────────────────────────────────────
  static const Color bg          = Color(0xFF0D0E1C);   // Near black
  static const Color surface     = Color(0xFF161829);
  static const Color card        = Color(0xFF1F2138);
  static const Color divider     = Color(0xFF2A2D44);

  // ── Text ──────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFEEEEFF);
  static const Color textSecondary = Color(0xFF9999BB);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        primaryColor: primary,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: surface,
          error: danger,
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -1,
          ),
          headlineMedium: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          bodyLarge: const TextStyle(fontSize: 16, color: textPrimary),
          bodyMedium: const TextStyle(fontSize: 14, color: textSecondary),
          labelSmall: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: textSecondary,
          ),
        ),
        cardTheme: CardTheme(
          color: card,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        dividerColor: divider,
        useMaterial3: true,
      );
}
