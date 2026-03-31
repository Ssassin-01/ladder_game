import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/neon_theme.dart';
import '../../core/neon_button.dart';
import 'ladder_game_mode.dart';
import 'ladder_game_view_model.dart';

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
    final viewModel = context.read<LadderGameViewModel>();
    final bool isOrderMode = viewModel.currentMode == LadderGameMode.order;
    
    _sortedResults = List.from(widget.results);
    _sortedResults.sort((a, b) {
      if (isOrderMode) {
        // "1번째", "2번째" 등에서 숫자만 추출하여 정렬
        int aNum = int.tryParse(a.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
        int bNum = int.tryParse(b.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
        return aNum.compareTo(bNum);
      } else {
        final aPass = a.text.contains('통과') || a.text.contains('꽝') || a.text.contains('얻어먹기');
        final bPass = b.text.contains('통과') || b.text.contains('꽝') || b.text.contains('얻어먹기');
        if (!aPass && bPass) return -1;
        if (aPass && !bPass) return 1;
        return 0;
      }
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
    final viewModel = context.watch<LadderGameViewModel>();
    final isDarkMode = themeProvider.isDarkMode;
    final bool isOrderMode = viewModel.currentMode == LadderGameMode.order;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    String titleText = '내기 결과';
    if (isOrderMode) {
      titleText = '최종 순위';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDarkMode ? NeonColors.cyan : NeonColors.solidCyan),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(titleText,
          style: TextStyle(
            color: isDarkMode ? NeonColors.cyan : NeonColors.solidCyan,
            fontSize: isLandscape ? 20 : 24,
            fontWeight: FontWeight.bold,
            shadows: isDarkMode ? NeonColors.getGlow(NeonColors.cyan) : null,
          )),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isOrderMode 
          ? _buildOrderModeLayout(isDarkMode)
          : (isLandscape 
              ? _buildLandscapeLayout(isDarkMode) 
              : _buildPortraitLayout(isDarkMode)),
      ),
    );
  }

  // --- 순서 모드 전용 레이아웃 (타임라인/랭킹 보드 스타일) ---
  Widget _buildOrderModeLayout(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _sortedResults.length,
      itemBuilder: (context, index) {
        final result = _sortedResults[index];
        final rankNum = index + 1;
        final cyanColor = isDarkMode ? NeonColors.cyan : NeonColors.solidCyan;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ScaleTransition(
            scale: _animations[index],
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cyanColor.withOpacity(0.3), width: 2),
                boxShadow: isDarkMode ? [
                  BoxShadow(color: cyanColor.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)
                ] : [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  // 좌측 순위 숫자 영역
                  Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: cyanColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        bottomLeft: Radius.circular(22),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$rankNum',
                      style: TextStyle(
                        color: cyanColor,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        shadows: isDarkMode ? NeonColors.getGlow(cyanColor) : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // 중앙 캐릭터 아이콘
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode ? Colors.black26 : Colors.grey[100],
                      border: Border.all(color: result.color.withOpacity(0.5), width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(result.emoji, style: const TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 20),
                  // 우측 이름 및 결과 텍스트
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.name,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.text,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rankNum == 1)
                    const Padding(
                      padding: EdgeInsets.only(right: 20),
                      child: Text('👑', style: TextStyle(fontSize: 28)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- 가로 모드 레이아웃 (좌우 분할) ---
  Widget _buildLandscapeLayout(bool isDarkMode) {
    final viewModel = context.read<LadderGameViewModel>();
    final bool isWinMode = viewModel.currentMode == LadderGameMode.win;
    final bool isTreatMode = viewModel.currentMode == LadderGameMode.treat;
    
    final subTitle = isWinMode ? '아쉬운 분들' : (isTreatMode ? '무료 급식소' : '살아남은 인원');

    final mainResults = _sortedResults.where((r) => 
        !(r.text.contains('통과') || r.text.contains('꽝') || r.text.contains('얻어먹기'))).toList();
    final subResults = _sortedResults.where((r) => 
        (r.text.contains('통과') || r.text.contains('꽝') || r.text.contains('얻어먹기'))).toList();

    return Row(
      children: [
        // 좌측: 당첨자/벌칙자/결제자 (스크롤 가능하지만 크게 강조)
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: mainResults.map((result) => _buildPenaltyCard(result, isDarkMode, compact: true, 
                isWinMode: isWinMode, isTreatMode: isTreatMode)).toList(),
            ),
          ),
        ),
        // 우측: 나머지 리스트 (그리드 형태)
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: isDarkMode ? Colors.white10 : Colors.black12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Text(subTitle, 
                    style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: subResults.length,
                    itemBuilder: (context, index) => _buildPassItem(subResults[index], isDarkMode),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 세로 모드 레이아웃 ---
  Widget _buildPortraitLayout(bool isDarkMode) {
    final viewModel = context.read<LadderGameViewModel>();
    final bool isWinMode = viewModel.currentMode == LadderGameMode.win;
    final bool isTreatMode = viewModel.currentMode == LadderGameMode.treat;

    final mainResults = _sortedResults.where((r) => 
        !(r.text.contains('통과') || r.text.contains('꽝') || r.text.contains('얻어먹기'))).toList();
    final subResults = _sortedResults.where((r) => 
        (r.text.contains('통과') || r.text.contains('꽝') || r.text.contains('얻어먹기'))).toList();

    String subTitle = '축하합니다! 살아남은 인원';
    if (isWinMode) {
      subTitle = '아쉬운 결과';
    } else if (isTreatMode) {
      subTitle = '무료 급식 성공!';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          ...mainResults.map((result) => _buildPenaltyCard(result, isDarkMode, isWinMode: isWinMode, isTreatMode: isTreatMode)),
          const SizedBox(height: 10),
          if (subResults.isNotEmpty)
            Text(subTitle,
              style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12, runSpacing: 12,
            alignment: WrapAlignment.center,
            children: subResults.map((result) => _buildPassItem(result, isDarkMode, width: (MediaQuery.of(context).size.width - 60) / 3))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPenaltyCard(ResultItem result, bool isDarkMode, {bool compact = false, bool isWinMode = false, bool isTreatMode = false, bool isOrderMode = false}) {
    final i = _sortedResults.indexOf(result);
    
    Color statusColor = Colors.red;
    String titleIcon = '🚨';
    String titleText = '벌칙 당첨';

    if (isWinMode) {
      statusColor = Colors.amber;
      titleIcon = '🎉';
      titleText = '축하합니다! 당첨';
    } else if (isTreatMode) {
      statusColor = Colors.orange;
      titleIcon = '💸';
      titleText = '오늘의 결제자!';
    } else if (isOrderMode) {
      statusColor = isDarkMode ? NeonColors.cyan : NeonColors.solidCyan;
      titleIcon = '👑';
      titleText = '영광의 1순위';
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ScaleTransition(
        scale: _animations[i],
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 20 : 30),
          decoration: BoxDecoration(
            color: isDarkMode ? statusColor.withOpacity(0.15) : statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: statusColor, width: 3),
            boxShadow: [
              BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: Column(
            children: [
              Text('$titleIcon $titleText $titleIcon',
                style: TextStyle(color: statusColor, fontSize: compact ? 14 : 18, fontWeight: FontWeight.w900, 
                letterSpacing: 2.0, shadows: isDarkMode ? NeonColors.getGlow(statusColor) : null)),
              SizedBox(height: compact ? 10 : 20),
              Container(
                width: compact ? 80 : 120, height: compact ? 80 : 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: isDarkMode ? Colors.black26 : Colors.white,
                  border: Border.all(color: statusColor, width: 3),
                ),
                alignment: Alignment.center,
                child: Text(result.emoji, style: TextStyle(fontSize: compact ? 45 : 70)),
              ),
              SizedBox(height: compact ? 10 : 20),
              Text(result.name, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, 
                fontSize: compact ? 20 : 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(result.text, textAlign: TextAlign.center,
                  style: TextStyle(color: isDarkMode ? Colors.white : (isWinMode || isTreatMode || isOrderMode ? (isDarkMode ? Colors.white : Colors.blueGrey[800]) : statusColor), 
                  fontSize: compact ? 22 : 28, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassItem(ResultItem result, bool isDarkMode, {double? width, bool isFullWidth = false}) {
    final i = _sortedResults.indexOf(result);
    final viewModel = context.read<LadderGameViewModel>();
    final bool isOrderMode = viewModel.currentMode == LadderGameMode.order;
    final statusColor = isDarkMode ? NeonColors.limeGreen : NeonColors.solidGreen;
    final cyanColor = isDarkMode ? NeonColors.cyan : NeonColors.solidCyan;

    return ScaleTransition(
      scale: _animations[i],
      child: Container(
        width: width ?? (isFullWidth ? double.infinity : null),
        margin: isFullWidth ? const EdgeInsets.only(bottom: 10) : EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isOrderMode ? cyanColor.withOpacity(0.5) : result.color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isFullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            if (isFullWidth) const SizedBox(width: 10),
            Text(result.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.name, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, 
                    fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  Text(result.text, style: TextStyle(color: isOrderMode ? cyanColor : statusColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
