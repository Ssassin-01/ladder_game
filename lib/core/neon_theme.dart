import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeonColors {
  // 기본 네온 컬러 (Hex Codes)
  static const Color hotPink = Color(0xFFFF007F);
  static const Color cyan = Color(0xFF00FFFF);
  static const Color limeGreen = Color(0xFF39FF14);
  static const Color electricYellow = Color(0xFFFFFF00);
  static const Color backgroundBlack = Color(0xFF000000);
  static const Color darkCharcoal = Color(0xFF121212);

  // Backward compatibility for existing code after removing light mode
  static Color get solidCyan => cyan;
  static Color get solidGreen => limeGreen;
  static Color get solidYellow => electricYellow;
  static Color get solidPink => hotPink;

  static List<BoxShadow> getGlow(Color color) {
    return [
      BoxShadow(blurRadius: 8, color: color.withOpacity(0.8)),
      BoxShadow(blurRadius: 15, color: color.withOpacity(0.4)),
    ];
  }
}

class ThemeProvider extends ChangeNotifier {
  bool get isDarkMode => true;

  void toggleTheme() {
    // Light mode has been removed as per user request.
  }

  ThemeData get currentTheme => darkTheme;

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NeonColors.backgroundBlack,
    primaryColor: NeonColors.cyan,
    textTheme: GoogleFonts.notoSansKrTextTheme(ThemeData.dark().textTheme),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: NeonColors.darkCharcoal,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    colorScheme: const ColorScheme.dark(
      primary: NeonColors.cyan,
      secondary: NeonColors.hotPink,
      surface: NeonColors.darkCharcoal,
    ),
  );
}
