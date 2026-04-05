import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeonColors {
  // Stitch 'Kawaii & Soft' Palette from home.png and penalty.png
  static const Color background = Color(0xFFFDFCF0); // Creamy Soft White
  static const Color primary = Color(0xFF6B8E23); // Olive Green
  static const Color stroke = Color(0xFF5D4037); // Chocolate Brown
  
  // Mode specific background colors from Stitch images
  static const Color modePenalty = Color(0xFFFFAB91); // Peach/Salmon
  static const Color modeWin = Color(0xFFD4E157); // Lime
  static const Color modeShoot = Color(0xFFFCE4EC); // Soft Pink
  static const Color modeOrder = Color(0xFFECEFF1); // Soft Grey
  static const Color modeTeam = Color(0xFFD4E157); // Lime/Yellow-Green
  
  static const Color surfaceCard = Color(0xFFF5F5F0); // Subtle Beige for cards
  static const Color textMain = Color(0xFF5D4037); // Dark Brown Text
  static const Color textSub = Color(0xFF8D6E63);
  
  // Compatibility aliases for other screens
  static const Color secondary = modeWin;
  static const Color error = Color(0xFFBE2D06); // Standard soft error red
  
  static List<BoxShadow> getGlow(Color color) {
    return [
      BoxShadow(blurRadius: 4, color: color.withOpacity(0.1)),
    ];
  }

  // 3D Button Effect Shadow
  static List<BoxShadow> get3DShadow(Color shadowColor) {
    return [
      BoxShadow(
        color: shadowColor,
        offset: const Offset(0, 4),
        blurRadius: 0,
      ),
    ];
  }
}

class NeonTheme {
  static ThemeData get forestTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: NeonColors.primary,
        surface: Colors.white,
        onSurface: NeonColors.textMain,
        primary: NeonColors.primary,
        secondary: NeonColors.modeWin,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: NeonColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: NeonColors.stroke),
        titleTextStyle: TextStyle(
          color: NeonColors.textMain,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold, color: NeonColors.textMain,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold, color: NeonColors.textMain,
        ),
      ),
      cardTheme: CardThemeData(
        color: NeonColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: Color(0xFFE0E0DB), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NeonColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
      ),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  bool get isDarkMode => false;
  void toggleTheme() {}
  ThemeData get currentTheme => NeonTheme.forestTheme;
}
