import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../../core/neon_theme.dart';
import '../../core/neon_button.dart';

class LadderResultScreen extends StatefulWidget {
  final String animalEmoji;
  final String animalName;
  final Color themeColor;
  final String resultText;

  const LadderResultScreen({
    super.key,
    required this.animalEmoji,
    required this.animalName,
    required this.themeColor,
    required this.resultText,
  });

  @override
  State<LadderResultScreen> createState() => _LadderResultScreenState();
}

class _LadderResultScreenState extends State<LadderResultScreen> with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playResultSound();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  Future<void> _playResultSound() async {
    try {
      await _audioPlayer.play(AssetSource('audio/result.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isWinner = widget.resultText.contains('당첨');
    final resultColor = isWinner 
        ? (themeProvider.isDarkMode ? NeonColors.hotPink : NeonColors.solidPink) 
        : (themeProvider.isDarkMode ? NeonColors.limeGreen : NeonColors.solidGreen);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              widget.themeColor.withOpacity(0.15),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            radius: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                children: [
                  Container(
                    width: 150, height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.themeColor, width: 4),
                      boxShadow: themeProvider.isDarkMode ? [BoxShadow(color: widget.themeColor.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)] : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(widget.animalEmoji, style: const TextStyle(fontSize: 80)),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    widget.resultText,
                    style: TextStyle(
                      color: resultColor,
                      fontSize: 60,
                      fontWeight: FontWeight.w900,
                      shadows: NeonColors.getGlow(resultColor, isDarkMode: themeProvider.isDarkMode),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.animalName}의 결과',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 80),
            // 이전으로 버튼 (노란색 텍스트 최적화)
            NeonButton(
              text: '이전으로',
              width: 180,
              color: themeProvider.isDarkMode ? Colors.amber : const Color(0xFFFFA000), // 진한 옐로우
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
