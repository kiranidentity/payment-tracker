import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ClearPay Inspired Palette
  static const Color primary = Color(0xFF4F46E5); // Royal Blue
  static const Color primaryDark = Color(0xFF1E1B4B); // Deep Indigo
  static const Color accent = Color(0xFF10B981); // Emerald Teal
  static const Color background = Color(0xFFF9FAFB); // Very Light Gray
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color textMain = Color(0xFF111827); // Gray 900
  static const Color textSub = Color(0xFF6B7280); // Gray 500

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: surface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textMain,
    ),
    
    // Typography (Inter)
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(color: textMain, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.inter(color: textMain, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.inter(color: textMain, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.inter(color: textMain, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(color: textMain),
      bodyMedium: GoogleFonts.inter(color: textSub),
      labelLarge: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w600),
    ),
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: textMain),
      titleTextStyle: GoogleFonts.inter(
        color: textMain,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    // Card Theme (Clean, Flat, Bordered)
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0, // Flat style
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1), // Subtle border
      ),
      margin: EdgeInsets.zero,
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
    
    // Elevated Button (Royal Blue Pill)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Taller
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    
    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),
  );
}
