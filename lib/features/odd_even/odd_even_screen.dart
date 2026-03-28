import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/neon_theme.dart';
import '../../core/neon_button.dart';

class OddEvenScreen extends StatefulWidget {
  const OddEvenScreen({super.key});

  @override
  State<OddEvenScreen> createState() => _OddEvenScreenState();
}

class _OddEvenScreenState extends State<OddEvenScreen> {
  String _resultText = '홀? 짝?';
  Color _resultColor = NeonColors.cyan;
  bool _isAnimating = false;

  void _playGame(String choice) async {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
      _resultText = '두구두구...';
      _resultColor = NeonColors.electricYellow;
    });

    // 긴장감을 위한 1초 대기
    await Future.delayed(const Duration(seconds: 1));

    final randomValue = Random().nextInt(100);
    final isEven = randomValue % 2 == 0;
    final result = isEven ? '짝' : '홀';

    setState(() {
      _isAnimating = false;
      if (choice == result) {
        _resultText = '정답! [$result]';
        _resultColor = NeonColors.limeGreen;
      } else {
        _resultText = '꽝! [$result]';
        _resultColor = NeonColors.hotPink;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: NeonColors.cyan),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 결과 창 (네온 텍스트)
            Container(
              height: 150,
              alignment: Alignment.center,
              child: Text(
                _resultText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _resultColor,
                  fontSize: 50,
                  fontWeight: FontWeight.w900,
                  shadows: NeonColors.getGlow(_resultColor),
                ),
              ),
            ),
            const SizedBox(height: 80),

            // 선택 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NeonButton(
                  text: '홀',
                  width: 120,
                  color: NeonColors.cyan,
                  onPressed: () => _playGame('홀'),
                ),
                const SizedBox(width: 20),
                NeonButton(
                  text: '짝',
                  width: 120,
                  color: NeonColors.cyan,
                  onPressed: () => _playGame('짝'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            Text(
              '운명에 맡기세요!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
