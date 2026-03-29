import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NeonColors {
  // 기본 네온 컬러 (Hex Codes)
  static const Color hotPink = Color(0xFFFF007F);
  static const Color cyan = Color(0xFF00FFFF);
  static const Color limeGreen = Color(0xFF39FF14);
  static const Color electricYellow = Color(0xFFFFFF00);
  static const Color backgroundBlack = Color(0xFF000000);
  static const Color darkCharcoal = Color(0xFF121212);

  // 라이트 모드용 선명한 색상 (Solid)
  static const Color solidPink = Color(0xFFD81B60);
  static const Color solidCyan = Color(0xFF00838F);
  static const Color solidGreen = Color(0xFF2E7D32);
  static const Color solidYellow = Color(0xFFFBC02D); // 진한 옐로우 (Amber 느낌)

  static List<Shadow> getGlow(Color color, {bool isDarkMode = true}) {
    if (!isDarkMode) {
      // 라이트 모드에선 번짐 효과 최소화
      return [Shadow(blurRadius: 1.5, color: Colors.black.withOpacity(0.2))];
    }
    return [
      Shadow(blurRadius: 8, color: color.withOpacity(0.8)),
      Shadow(blurRadius: 15, color: color.withOpacity(0.4)),
    ];
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get currentTheme {
    return _isDarkMode ? darkTheme : lightTheme;
  }

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NeonColors.backgroundBlack,
    primaryColor: NeonColors.cyan,
    colorScheme: const ColorScheme.dark(
      primary: NeonColors.cyan,
      secondary: NeonColors.hotPink,
      surface: NeonColors.darkCharcoal,
    ),
  );

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    primaryColor: NeonColors.solidCyan,
    colorScheme: const ColorScheme.light(
      primary: NeonColors.solidCyan,
      secondary: NeonColors.solidPink,
      surface: Colors.white,
    ),
  );
}
