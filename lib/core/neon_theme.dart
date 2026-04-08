import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum LadderThemeId {
  forest('Kawaii Forest'),
  neon('Midnight Neon'),
  ocean('Ocean Breeze');

  final String label;
  const LadderThemeId(this.label);
}

class LadderThemeData {
  final Color background;
  final Color primary;
  final Color onPrimary; // primary 위 텍스트 색상
  final Color accent;
  final Color onAccent; // accent 위 텍스트 색상
  final Color stroke;
  final Color shadow;
  final Color cardBg;
  final Color onCardBg; // cardBg 위 텍스트 색상
  final Color textMain;
  final Color textSub;
  
  // 모드별 포인트 컬러
  final Color modePenalty;
  final Color modeWin;
  final Color modeShoot;
  final Color modeOrder;
  final Color modeTeam;

  const LadderThemeData({
    required this.background,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.onAccent,
    required this.stroke,
    required this.shadow,
    required this.cardBg,
    required this.onCardBg,
    required this.textMain,
    required this.textSub,
    required this.modePenalty,
    required this.modeWin,
    required this.modeShoot,
    required this.modeOrder,
    required this.modeTeam,
  });
}

class NeonColors {
  static LadderThemeData getTheme(LadderThemeId id) {
    switch (id) {
      case LadderThemeId.forest:
        return const LadderThemeData(
          background: Color(0xFFFEFCF4),
          primary: Color(0xFF5F6A00),
          onPrimary: Colors.white,
          accent: Color(0xFFDBEC6D),
          onAccent: Color(0xFF5D4037),
          stroke: Color(0xFF5D4037),
          shadow: Color(0xFF7B5F45),
          cardBg: Color(0xFFFBF9F1),
          onCardBg: Color(0xFF5D4037),
          textMain: Color(0xFF5D4037),
          textSub: Color(0xFF65655F),
          modePenalty: Color(0xFFFED3C7),
          modeWin: Color(0xFFD1E4FF),
          modeShoot: Color(0xFFDBEC6D),
          modeOrder: Color(0xFFFFD9B8),
          modeTeam: Color(0xFFE9E9DE),
        );
      case LadderThemeId.neon:
        return const LadderThemeData(
          background: Color(0xFF0F0F1A), 
          primary: Color(0xFFFF007F),    
          onPrimary: Colors.white,
          accent: Color(0xFF00FFFF),     
          onAccent: Color(0xFF0F0F1A),   
          stroke: Color(0xFFFF007F),     
          shadow: Color(0xFFFF007F),
          cardBg: Color(0xFF1E1E2E),
          onCardBg: Colors.white,
          textMain: Colors.white,
          textSub: Color(0xFF9494B8),
          modePenalty: Color(0xFFFF007F),
          modeWin: Color(0xFF00FFFF),
          modeShoot: Color(0xFFFFFF00),  
          modeOrder: Color(0xFFBC13FE),
          modeTeam: Color(0xFF2D2D44),
        );
      case LadderThemeId.ocean:
        return const LadderThemeData(
          background: Color(0xFFE8F1F9), // 배경을 살짝 더 차분하게
          primary: Color(0xFF0066FF),
          onPrimary: Colors.white,
          accent: Color(0xFF004D99),     // 더 짙은 내비 블루로 입체감 부여
          onAccent: Colors.white,
          stroke: Color(0xFF004D99),     // 테두리를 명확하게
          shadow: Color(0xFF80B3FF),
          cardBg: Color(0xFFFFFFFF),
          onCardBg: Color(0xFF003366),
          textMain: Color(0xFF003366),   // 가독성 높은 딥 블루
          textSub: Color(0xFF4D80B3),
          modePenalty: Color(0xFFD9E9FF),
          modeWin: Color(0xFFA6D2FF),
          modeShoot: Color(0xFF1976D2), // 밝은 노랑 대신 진한 파랑으로 시인성 확보
          modeOrder: Color(0xFFBBE1FA),
          modeTeam: Color(0xFFF0F8FF),
        );
    }
  }

  // Backward compatibility - defaults to forest
  static const Color background = Color(0xFFFEFCF4);
  static const Color primary = Color(0xFF5F6A00);
  static const Color accent = Color(0xFFDBEC6D);
  static const Color stroke = Color(0xFF5D4037);
  static const Color shadow = Color(0xFF7B5F45);
  static const Color cardBg = Color(0xFFFBF9F1);
  static const Color textMain = Color(0xFF383833);
  static const Color textSub = Color(0xFF65655F);
  
  static const Color pointPink = Color(0xFFFED3C7);
  static const Color pointGreen = Color(0xFFDBEC6D);
  static const Color pointOrange = Color(0xFFFED9B8);

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
  static BoxDecoration getCardDecoration({double radius = 32.0, Color bg = NeonColors.cardBg, Color? strokeColor}) {
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: strokeColor ?? NeonColors.stroke, width: 2.0),
    );
  }

  static ThemeData getThemeData(LadderThemeId themeId) {
    final colors = NeonColors.getTheme(themeId);
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        surface: colors.cardBg,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        headlineMedium: TextStyle(
          color: colors.textMain,
          fontWeight: FontWeight.w900,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: colors.textMain,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  // Backward compatibility
  static ThemeData get themeData => getThemeData(LadderThemeId.forest);
  static ThemeData get forestTheme => getThemeData(LadderThemeId.forest);
}

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme = NeonTheme.themeData;
  ThemeData get currentTheme => _currentTheme;

  void toggleTheme() {
    notifyListeners();
  }
}
