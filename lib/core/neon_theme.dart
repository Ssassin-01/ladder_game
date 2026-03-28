import 'package:flutter/material.dart';

class NeonColors {
  // GEMINI.md에 정의된 핵심 네온 컬러
  static const Color hotPink = Color(0xFFFF007F);
  static const Color cyberCyan = Color(0xFF00FFFF);
  static const Color limeGreen = Color(0xFF39FF14);
  static const Color electricYellow = Color(0xFFFFFF00);
  static const Color backgroundBlack = Color(0xFF000000);
  static const Color darkCharcoal = Color(0xFF121212);

  // 네온 발광 효과를 위한 Shadow 생성 함수
  static List<Shadow> getGlow(Color color) {
    return [
      Shadow(blurRadius: 10, color: color, offset: Offset.zero),
      Shadow(blurRadius: 20, color: color, offset: Offset.zero),
    ];
  }
}
