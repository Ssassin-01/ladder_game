import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/neon_theme.dart';
import '../../core/neon_button.dart';

class ResultItem {
  final String emoji;
  final String name;
  final Color color;
  final String text;

  ResultItem({
    required this.emoji,
    required this.name,
    required this.color,
    required this.text,
  });
}

class LadderResultScreen extends StatefulWidget {
  final List<ResultItem> results;

  const LadderResultScreen({
    super.key,
    required this.results,
  });

  @override
  State<LadderResultScreen> createState() => _LadderResultScreenState();
}

class _LadderResultScreenState extends State<LadderResultScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late List<ResultItem> _sortedResults;

  @override
  void initState() {
    super.initState();
    
    // 당첨된 사람을 리스트의 첫 번째로 정렬
    _sortedResults = List.from(widget.results);
    _sortedResults.sort((a, b) {
      final aWin = a.text.contains('당첨');
      final bWin = b.text.contains('당첨');
      if (aWin && !bWin) return -1;
      if (!aWin && bWin) return 1;
      return 0;
    });

    _controllers = List.generate(
      _sortedResults.length,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500 + (i * 100)),
      ),
    );

    _animations = _controllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.1).chain(CurveTween(curve: Curves.easeOut)),
          weight: 70,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 30,
        ),
      ]).animate(c);
    }).toList();

    for (var controller in _controllers) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDarkMode ? NeonColors.cyan : NeonColors.solidCyan),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '내기 결과',
          style: TextStyle(
            color: isDarkMode ? NeonColors.cyan : NeonColors.solidCyan,
            fontSize: isLandscape ? 20 : 24,
            fontWeight: FontWeight.bold,
            shadows: isDarkMode ? NeonColors.getGlow(NeonColors.cyan) : null,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // 1. 당첨자 섹션 (단독 배치)
              ..._sortedResults.where((r) => r.text.contains('당첨')).map((result) {
                final i = _sortedResults.indexOf(result);
                final statusColor = isDarkMode ? NeonColors.hotPink : NeonColors.solidPink;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: ScaleTransition(
                    scale: _animations[i],
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: isDarkMode ? statusColor.withOpacity(0.15) : statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFFFFD700) : statusColor, 
                          width: 4
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode ? const Color(0xFFFFD700).withOpacity(0.6) : statusColor.withOpacity(0.6), 
                            blurRadius: 40, 
                            spreadRadius: 8
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            width: 130, height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle, color: isDarkMode ? Colors.black26 : Colors.white,
                              border: Border.all(
                                color: isDarkMode ? const Color(0xFFFFD700) : result.color, 
                                width: 4
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode ? const Color(0xFFFFD700).withOpacity(0.5) : result.color.withOpacity(0.5), 
                                  blurRadius: 25
                                )
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(result.emoji, style: const TextStyle(fontSize: 75)),
                          ),
                          const SizedBox(height: 20),
                          Text(result.name, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          Text(
                            result.text,
                            style: TextStyle(
                              color: isDarkMode ? const Color(0xFFFFD700) : statusColor, 
                              fontSize: 52, 
                              fontWeight: FontWeight.w900,
                              shadows: isDarkMode ? NeonColors.getGlow(const Color(0xFFFFD700)) : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              
              // 2. 통과자 섹션 (Wrap을 사용하여 촘촘하게 정렬)
              Wrap(
                spacing: 15,
                runSpacing: 15,
                alignment: WrapAlignment.center,
                children: _sortedResults.where((r) => !r.text.contains('당첨')).map((result) {
                  final i = _sortedResults.indexOf(result);
                  final statusColor = isDarkMode ? NeonColors.limeGreen : NeonColors.solidGreen;
                  final itemWidth = (MediaQuery.of(context).size.width - 70) / (isLandscape ? 4 : 3);

                  return Opacity(
                    opacity: 0.6,
                    child: ScaleTransition(
                      scale: _animations[i],
                      child: Container(
                        width: itemWidth,
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: result.color.withOpacity(0.3), width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(result.emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 8),
                            Text(result.name, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(result.text, style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
