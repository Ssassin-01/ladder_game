import 'package:flutter/material.dart';
import '../../core/neon_theme.dart';
import '../../core/neon_button.dart';
import '../odd_even/odd_even_screen.dart';
import '../ladder_game/ladder_settings_screen.dart';
import '../snail_race/snail_race_screen.dart';
import '../pinball/pinball_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.backgroundBlack,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 앱 타이틀 (네온 효과 강조)
              Text(
                '친구랑\n내기 한판 ㄱ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: NeonColors.electricYellow,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  shadows: NeonColors.getGlow(NeonColors.electricYellow),
                ),
              ),
              const SizedBox(height: 60),

              // 게임 선택 버튼 리스트
              _buildGameButton(
                context,
                text: '홀짝 게임',
                color: NeonColors.cyan,
                targetScreen: const OddEvenScreen(),
              ),
              const SizedBox(height: 20),

              _buildGameButton(
                context,
                text: '사다리 게임',
                color: NeonColors.limeGreen,
                targetScreen: const LadderSettingsScreen(),
              ),
              const SizedBox(height: 20),

              _buildGameButton(
                context,
                text: '달팽이 경주',
                color: NeonColors.hotPink,
                targetScreen: const SnailRaceScreen(),
              ),
              const SizedBox(height: 20),

              _buildGameButton(
                context,
                text: '핀볼 게임',
                color: NeonColors.electricYellow,
                targetScreen: const PinballScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 공통 버튼 빌더 함수
  Widget _buildGameButton(
    BuildContext context, {
    required String text,
    required Color color,
    required Widget targetScreen,
  }) {
    return NeonButton(
      text: text,
      color: color,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      },
    );
  }
}
