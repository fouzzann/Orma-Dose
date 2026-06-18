import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - Light Mode
  static const Color primaryTeal = Color(0xFF0AB0BC);
  static const Color primaryBlue = Color(0xFF0D8AD4);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color alertOrange = Color(0xFFFF9F43);
  static const Color alertRed = Color(0xFFFF6C5C);
  
  static const Color bgLight = Color(0xFFF4F8FA);
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMutedLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Brand Colors - Dark Mode
  static const Color bgDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryTeal, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFF9F43), Color(0xFFE67E22)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF6C5C), Color(0xFFE74C3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphic Card Decoration Helper
  static BoxDecoration glassDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark 
          ? Colors.white.withOpacity(0.06) 
          : Colors.white.withOpacity(0.75),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark 
            ? Colors.white.withOpacity(0.1) 
            : Colors.white.withOpacity(0.4),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark 
              ? Colors.black.withOpacity(0.2) 
              : Color(0xFF0D8AD4).withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        secondary: primaryBlue,
        surface: cardLight,
        background: bgLight,
        error: alertRed,
        onPrimary: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
        headlineLarge: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: textDark),
        headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: textDark),
        titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: textDark),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textMutedLight),
        labelLarge: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: primaryTeal),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56), // Large touch targets
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryTeal,
        secondary: primaryBlue,
        surface: cardDark,
        background: bgDark,
        error: alertRed,
        onPrimary: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textLight),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: textLight),
        headlineLarge: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: textLight),
        headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: textLight),
        titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: textLight),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textLight),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: textLight),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textMutedDark),
        labelLarge: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: primaryTeal),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56), // Large touch targets
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
