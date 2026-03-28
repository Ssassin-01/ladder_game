import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/neon_theme.dart';
import '../../core/neon_button.dart';
import 'ladder_game_view_model.dart';
import 'ladder_painter.dart';
import 'ladder_result_screen.dart';

class LadderGameScreen extends StatefulWidget {
  const LadderGameScreen({super.key});

  @override
  State<LadderGameScreen> createState() => _LadderGameScreenState();
}

class _LadderGameScreenState extends State<LadderGameScreen> with TickerProviderStateMixin {
  AnimationController? _shakeController;
  Animation<Offset>? _shakeAnimation;
  AnimationController? _pathController;
  late Animation<double> _curvedPathAnimation;
  
  Map<int, List<Offset>>? _activePaths;
  bool _isAnimating = false;
  final List<TextEditingController> _controllers = [];
  List<int>? _allResults;

  @override
  void initState() {
    super.initState();
    // 가림막 상태 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LadderGameViewModel>().resetShroud();
    });

    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(0.01, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.01, 0), end: const Offset(-0.01, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.01, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController!, curve: Curves.linear));

    _pathController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500));
    _curvedPathAnimation = CurvedAnimation(parent: _pathController!, curve: Curves.easeInOutSine);
  }

  void _updateControllers(LadderGameViewModel viewModel) {
    if (_controllers.length != viewModel.playerCount) {
      if (_controllers.length > viewModel.playerCount) {
        for (int i = viewModel.playerCount; i < _controllers.length; i++) { _controllers[i].dispose(); }
        _controllers.removeRange(viewModel.playerCount, _controllers.length);
      } else {
        for (int i = _controllers.length; i < viewModel.playerCount; i++) {
          _controllers.add(TextEditingController(text: viewModel.bottomResults[i]));
        }
      }
    }
  }

  @override
  void dispose() {
    _shakeController?.dispose();
    _pathController?.dispose();
    for (var controller in _controllers) { controller.dispose(); }
    super.dispose();
  }

  void _startAll(LadderGameViewModel viewModel, Size size) async {
    if (_isAnimating || _pathController == null) return;
    setState(() {
      _isAnimating = true; _allResults = null; _activePaths = {};
      for (int i = 0; i < viewModel.playerCount; i++) { _activePaths![i] = viewModel.getPath(i, size); }
    });
    if (viewModel.isShroudActive) viewModel.setShroudActive(false);
    
    // 속도 레벨에 따른 동적 기간 설정
    int ms = (7000 - (viewModel.speedLevel * 1200)).clamp(1000, 7000);
    _pathController!.duration = Duration(milliseconds: ms);

    _pathController!.reset();
    try {
      await _pathController!.forward().orCancel;
    } on TickerCanceled {
      return; // 애니메이션 취소 시 중단
    }

    if (!mounted || !_isAnimating) return;

    _shakeController?.forward(from: 0);
    int winnerIdx = 0;
    for(int i=0; i<viewModel.playerCount; i++) {
      if(viewModel.bottomResults[viewModel.getResultIndex(i)].contains('당첨')) { winnerIdx = i; break; }
    }
    final participant = viewModel.currentParticipants[winnerIdx];
    final resultIdx = viewModel.getResultIndex(winnerIdx);
    final resultText = viewModel.bottomResults[resultIdx];
    
    setState(() { 
      _allResults = List.generate(viewModel.playerCount, (i) => viewModel.getResultIndex(i)); 
      _isAnimating = false; 
    });
    
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _pathController!.status != AnimationStatus.completed) return;

    Navigator.push(context, MaterialPageRoute(builder: (context) => LadderResultScreen(animalEmoji: participant.emoji, animalName: participant.animalType, themeColor: participant.color, resultText: resultText)));
  }

  void _startIndividual(int index, LadderGameViewModel viewModel, Size size) async {
    if (_isAnimating || _pathController == null || viewModel.isShroudActive) return;
    setState(() { _isAnimating = true; _allResults = null; _activePaths = {index: viewModel.getPath(index, size)}; });
    
    int ms = (7000 - (viewModel.speedLevel * 1200)).clamp(1000, 7000);
    _pathController!.duration = Duration(milliseconds: ms);

    _pathController!.reset();
    try {
      await _pathController!.forward().orCancel;
    } on TickerCanceled {
      return;
    }

    if (!mounted || !_isAnimating) return;

    final resultIdx = viewModel.getResultIndex(index);
    _shakeController?.forward(from: 0);
    setState(() { _allResults = [resultIdx]; _isAnimating = false; });
    
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _pathController!.status != AnimationStatus.completed) return;

    final participant = viewModel.currentParticipants[index];
    final resultText = viewModel.bottomResults[resultIdx];
    Navigator.push(context, MaterialPageRoute(builder: (context) => LadderResultScreen(animalEmoji: participant.emoji, animalName: participant.animalType, themeColor: participant.color, resultText: resultText)));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LadderGameViewModel>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    _updateControllers(viewModel);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text('사다리 게임', style: TextStyle(color: isDarkMode ? NeonColors.cyan : NeonColors.solidCyan, shadows: isDarkMode ? NeonColors.getGlow(NeonColors.cyan) : null)),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: isDarkMode ? NeonColors.cyan : NeonColors.solidCyan), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, color: isDarkMode ? NeonColors.cyan : NeonColors.solidCyan),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, mainConstraints) {
            final double totalWidth = mainConstraints.maxWidth;
            final double playerGap = totalWidth / (viewModel.playerCount + 1);
            
            // 반응형 크기 계산
            final double avatarSize = (playerGap * 0.9).clamp(35.0, 70.0);
            final double emojiSize = (avatarSize * 0.5).clamp(18.0, 36.0);
            final double resultWidth = (playerGap * 0.95).clamp(45.0, 85.0);
            final double fontSize = (resultWidth * 0.2).clamp(9.0, 14.0);

            return Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      final sectionWidth = size.width / (viewModel.playerCount + 1);
                      final sectionHeight = size.height / (viewModel.sectionCount + 2);

                      return SlideTransition(
                        position: _shakeAnimation!,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: LadderPainter(
                                  playerCount: viewModel.playerCount,
                                  sectionCount: viewModel.sectionCount,
                                  ladderBars: viewModel.ladderBars,
                                  activePaths: _activePaths,
                                  participantColors: viewModel.currentParticipants.map((p) => p.color).toList(),
                                  animation: _curvedPathAnimation,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                            ),
                            ...List.generate(viewModel.playerCount, (i) {
                              final p = viewModel.currentParticipants[i];
                              return Positioned(
                                top: sectionHeight * 0.1,
                                left: sectionWidth * (i + 1) - (avatarSize / 2),
                                child: GestureDetector(
                                  onTap: () => _startIndividual(i, viewModel, size),
                                  child: Container(
                                    width: avatarSize, height: avatarSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle, 
                                      color: Theme.of(context).scaffoldBackgroundColor, 
                                      border: Border.all(color: p.color, width: 2.5), 
                                      boxShadow: isDarkMode ? [BoxShadow(color: p.color.withOpacity(0.3), blurRadius: 8)] : null
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(p.emoji, style: TextStyle(fontSize: emojiSize)),
                                  ),
                                ),
                              );
                            }),
                            if (viewModel.isShroudActive)
                              Positioned(
                                top: sectionHeight * 1.5 + 25,
                                bottom: sectionHeight * 1.5 - 25,
                                left: sectionWidth * 0.5, right: sectionWidth * 0.5,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.85), 
                                    borderRadius: BorderRadius.circular(20), 
                                    border: Border.all(color: isDarkMode ? NeonColors.hotPink.withOpacity(0.5) : Colors.grey.withOpacity(0.3), width: 2), 
                                    boxShadow: isDarkMode ? [BoxShadow(color: NeonColors.hotPink.withOpacity(0.2), blurRadius: 30, spreadRadius: 10)] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('가로선 개수', style: TextStyle(color: isDarkMode ? NeonColors.electricYellow : NeonColors.solidYellow, fontSize: 18, fontWeight: FontWeight.bold, shadows: isDarkMode ? NeonColors.getGlow(NeonColors.electricYellow) : null)),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _smallCircleButton('-', () { if (viewModel.sectionCount > 5) viewModel.setSectionCount(viewModel.sectionCount - 1); }, isDarkMode),
                                          Container(width: 50, alignment: Alignment.center, child: Text('${viewModel.sectionCount}', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold))),
                                          _smallCircleButton('+', () { if (viewModel.sectionCount < 20) viewModel.setSectionCount(viewModel.sectionCount + 1); }, isDarkMode),
                                        ],
                                      ),
                                      const SizedBox(height: 30),
                                      NeonButton(text: 'START', width: 140, color: NeonColors.hotPink, onPressed: () => _startAll(viewModel, size)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  height: 140,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 50,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: List.generate(viewModel.playerCount, (i) {
                            final isTarget = _allResults?.contains(i) ?? false;
                            final resultText = _controllers[i].text;
                            final bool isPenalty = resultText.contains('당첨') || (resultText != '통과' && isTarget);
                            final Color statusColor = isPenalty ? (isDarkMode ? NeonColors.hotPink : NeonColors.solidPink) : (isDarkMode ? NeonColors.limeGreen : NeonColors.solidGreen);

                            return Positioned(
                              left: playerGap * (i + 1) - (resultWidth / 2),
                              child: Container(
                                width: resultWidth, height: 40,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.black87 : Colors.white, 
                                  border: Border.all(color: isTarget ? statusColor : statusColor.withOpacity(0.3), width: isTarget ? 2.5 : 1.5), 
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: (isTarget && isDarkMode) ? [BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 8)] : null,
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: IntrinsicWidth(
                                        child: TextField(
                                          textAlign: TextAlign.center, controller: _controllers[i],
                                          onChanged: (val) => viewModel.updateResult(i, val),
                                          style: TextStyle(color: isTarget ? statusColor : (isDarkMode ? Colors.white : Colors.black87), fontSize: fontSize, fontWeight: FontWeight.bold),
                                          decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                      NeonButton(
                        text: '사다리 섞기', width: 150, color: isDarkMode ? NeonColors.limeGreen : NeonColors.solidGreen,
                        onPressed: () {
                          _pathController?.stop();
                          setState(() { 
                            _isAnimating = false;
                            _allResults = null; 
                            _activePaths = null; 
                          });
                          viewModel.refreshLadder(); 
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _smallCircleButton(String text, VoidCallback onPressed, bool isDarkMode) {
    final color = isDarkMode ? NeonColors.cyan : NeonColors.solidCyan;
    return InkWell(
      onTap: onPressed, borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.5)),
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
