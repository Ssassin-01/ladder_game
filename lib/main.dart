import 'package:flutter/material.dart';
import 'core/neon_theme.dart';
import 'core/neon_button.dart';

void main() {
  runApp(const BettingApp());
}

class BettingApp extends StatelessWidget {
  const BettingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '친구랑 내기 한판 ㄱ?',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: NeonColors.backgroundBlack,
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 타이틀 (네온 효과 적용)
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
            const SizedBox(height: 80),

            // 게임 선택 버튼들
            NeonButton(
              text: '홀짝 게임',
              color: NeonColors.cyberCyan,
              onPressed: () {
                print('홀짝 게임 시작!');
                // TODO: 3단계 구현 시 이동 로직 추가
              },
            ),
            const SizedBox(height: 20),

            NeonButton(
              text: '사다리 타기',
              color: NeonColors.limeGreen,
              onPressed: () {
                print('사다리 타기 시작!');
              },
            ),
            const SizedBox(height: 20),

            NeonButton(
              text: '달팽이 경주',
              color: NeonColors.hotPink,
              onPressed: () {
                print('달팽이 경주 시작!');
              },
            ),
            const SizedBox(height: 20),

            NeonButton(
              text: '핀볼 게임',
              color: NeonColors.electricYellow,
              onPressed: () {
                print('핀볼 게임 시작!');
              },
            ),
          ],
        ),
      ),
    );
  }
}
