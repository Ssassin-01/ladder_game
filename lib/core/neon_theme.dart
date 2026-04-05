import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeonColors {
  // Stitch extracted tokens for Kawaii Ladder
  static const Color background = Color(0xFFFEFCF4); // Pale Cream
  static const Color primary = Color(0xFF5F6A00);    // Olive Green
  static const Color accent = Color(0xFFDBEC6D);     // Light Lime
  static const Color stroke = Color(0xFF5D4037);     // Dark Chocolate Brown
  static const Color shadow = Color(0xFF7B5F45);     // Medium Brown (Shadow)
  
  static const Color cardBg = Color(0xFFFBF9F1);     // Surface Container Low
  static const Color textMain = Color(0xFF383833);   // Dark Charcoal
  static const Color textSub = Color(0xFF65655F);    // Medium Grey/Taupe
  
  static const Color pointPink = Color(0xFFFED3C7);  // Tertiary Fixed
  static const Color pointGreen = Color(0xFFDBEC6D); // Secondary Fixed
  static const Color pointOrange = Color(0xFFFED9B8); // Primary Fixed

  // ---- Backward Compatibility for Home Screen ----
  static const Color modePenalty = Color(0xFFFED3C7);
  static const Color modeWin = Color(0xFFD1E4FF);
  static const Color modeShoot = Color(0xFFDBEC6D);
  static const Color modeOrder = Color(0xFFFFD9B8);
  static const Color modeTeam = Color(0xFFE9E9DE);

  static List<BoxShadow> get3DShadow(Color color) {
    return [
      BoxShadow(
        color: color,
        offset: const Offset(0, 4),
        blurRadius: 0,
      ),
    ];
  }
}

class NeonTheme {
  // 3-Card Layout common decoration
  static BoxDecoration getCardDecoration({double radius = 32.0, Color bg = NeonColors.cardBg}) {
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: NeonColors.stroke, width: 2.0),
    );
  }

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: NeonColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: NeonColors.primary,
        surface: NeonColors.cardBg,
      ),
      cardTheme: const CardThemeData(
        color: NeonColors.cardBg,
        elevation: 0,
        margin: EdgeInsets.all(0),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        headlineMedium: const TextStyle(
          color: NeonColors.textMain,
          fontWeight: FontWeight.w900,
          fontSize: 24,
        ),
        titleLarge: const TextStyle(
          color: NeonColors.textMain,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  // Backward compatibility for main.dart
  static ThemeData get forestTheme => themeData;
}

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme = NeonTheme.themeData;
  ThemeData get currentTheme => _currentTheme;

  void toggleTheme() {
    notifyListeners();
  }
}
