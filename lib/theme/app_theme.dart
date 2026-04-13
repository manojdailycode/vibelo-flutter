import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  VIBELO COLOR PALETTE  –  "Cosmic Vibe"
//  100% Original Design — No Copyright Issues
// ─────────────────────────────────────────────
class VColors {
  // Backgrounds
  static const Color bg = Color(0xFF070B14); // deep space
  static const Color surface = Color(0xFF111827); // dark navy
  static const Color card = Color(0xFF1A2236); // card navy
  static const Color cardLight = Color(0xFF212D45); // lighter card

  // Brand
  static const Color primary = Color(0xFF7B5EA7); // cosmic violet
  static const Color primaryLt = Color(0xFF9B7FD4); // light violet
  static const Color secondary = Color(0xFF00C9A7); // vibrant teal
  static const Color accent = Color(0xFFFF6B9D); // coral pink
  static const Color amber = Color(0xFFFFB830); // amber

  // Text
  static const Color textPri = Color(0xFFFFFFFF);
  static const Color textSec = Color(0xFF8892A4);
  static const Color textMuted = Color(0xFF4A5568);

  // Status
  static const Color success = Color(0xFF48BB78);
  static const Color error = Color(0xFFFC8181);
  static const Color premium = Color(0xFFFFD700);
  static const Color divider = Color(0xFF1E2A3D);

  // Gradients
  static const LinearGradient primaryGrad = LinearGradient(
    colors: [Color(0xFF7B5EA7), Color(0xFF4A90D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGrad = LinearGradient(
    colors: [Color(0xFF0D1117), Color(0xFF070B14)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGrad = LinearGradient(
    colors: [Color(0xFF1A2236), Color(0xFF111827)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGrad = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGrad = LinearGradient(
    colors: [Color(0xFF00C9A7), Color(0xFF0097A7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: VColors.primary,
        secondary: VColors.secondary,
        surface: VColors.surface,
        error: VColors.error,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: VColors.textPri,
        displayColor: VColors.textPri,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: VColors.textPri,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: VColors.textPri),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VColors.primary,
          foregroundColor: VColors.textPri,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.poppins(
          color: VColors.textMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(color: VColors.textSec),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: VColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: VColors.surface,
        selectedItemColor: VColors.primary,
        unselectedItemColor: VColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: VColors.divider,
        thickness: 1,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: VColors.primary,
        inactiveTrackColor: VColors.divider,
        thumbColor: VColors.primaryLt,
        overlayColor: VColors.primary.withValues(alpha: 0.2),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
    );
  }
}
