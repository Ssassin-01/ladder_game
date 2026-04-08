import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/neon_theme.dart';
import '../../core/widgets/neon_3d_button.dart';
import '../../core/sound_manager.dart';
import 'ladder_game_view_model.dart';
import 'ladder_game_mode.dart';
import 'ladder_painter.dart';
import 'ladder_result_screen.dart';

class LadderGameScreen extends StatefulWidget {
  const LadderGameScreen({super.key});

  @override
  State<LadderGameScreen> createState() => _LadderGameScreenState();
}

class _LadderGameScreenState extends State<LadderGameScreen>
    with TickerProviderStateMixin {
  AnimationController? _shakeController;
  Animation<Offset>? _shakeAnimation;

  final Map<int, AnimationController> _activeControllers = {};
  final Map<int, Animation<double>> _activeAnimations = {};
  final Set<int> _finishedEndIndices = {};
  final Set<int> _selectedStartIndices = {};

  final Map<int, int> _endIndexSnapshot = {};
  final Map<int, String> _resultTextSnapshot = {};

  bool _isAnimating = false;
  bool _isNavigationTriggered = false;
  final List<TextEditingController> _controllers = [];
  final TextEditingController _sectionCountController = TextEditingController();
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<LadderGameViewModel>();
      viewModel.resetShroud();
      _sectionCountController.text = '${viewModel.sectionCount}';
    });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(4, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(4, 0), end: const Offset(-4, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-4, 0), end: const Offset(3, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(3, 0), end: const Offset(-3, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-3, 0), end: const Offset(2, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(2, 0), end: const Offset(-2, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-2, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController!, curve: Curves.easeInOut));
  }

  void _updateControllers(LadderGameViewModel viewModel) {
    if (_controllers.length != viewModel.playerCount) {
      if (_controllers.length > viewModel.playerCount) {
        for (int i = viewModel.playerCount; i < _controllers.length; i++) {
          _controllers[i].dispose();
        }
        _controllers.removeRange(viewModel.playerCount, _controllers.length);
      } else {
        for (int i = _controllers.length; i < viewModel.playerCount; i++) {
          // Safety Check: Ensure the results exist before mapping to controllers
          final initialValue = i < viewModel.bottomResults.length ? viewModel.bottomResults[i] : '';
          _controllers.add(TextEditingController(text: initialValue));
        }
      }
    }
    if (!_isAnimating) {
      for (int i = 0; i < viewModel.playerCount; i++) {
        // Safety: Ensure both lists have the required index
        if (i < _controllers.length && i < viewModel.bottomResults.length) {
          if (_controllers[i].text != viewModel.bottomResults[i]) {
            _controllers[i].text = viewModel.bottomResults[i];
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _shakeController?.dispose();
    for (var c in _activeControllers.values) {
      c.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    _stopStepping();
    super.dispose();
  }

  void _startStepping(bool isIncrement, LadderGameViewModel viewModel) {
    _stopStepping();
    final action = () {
      if (isIncrement) {
        if (viewModel.sectionCount < 100) {
          viewModel.setSectionCount(viewModel.sectionCount + 1);
          _sectionCountController.text = '${viewModel.sectionCount}';
          SoundManager().playTick();
        }
      } else {
        if (viewModel.sectionCount > 1) {
          viewModel.setSectionCount(viewModel.sectionCount - 1);
          _sectionCountController.text = '${viewModel.sectionCount}';
          SoundManager().playTick();
        }
      }
    };
    action();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 150), (_) => action());
  }

  void _stopStepping() {
    _stepTimer?.cancel();
    _stepTimer = null;
  }

  void _navigateToResults(LadderGameViewModel viewModel) {
    if (!mounted || _selectedStartIndices.isEmpty || _isNavigationTriggered) return;
    _isNavigationTriggered = true;

    final results = _selectedStartIndices.map((startIdx) {
      // Bounds check for safety before navigation
      if (startIdx >= viewModel.currentParticipants.length) return null;
      
      final p = viewModel.currentParticipants[startIdx];
      final resIdx = _endIndexSnapshot[startIdx] ?? viewModel.getResultIndex(startIdx);
      
      // Safety: Ensure the calculated end index is within bottomResults bounds
      final safeResIdx = (resIdx < viewModel.bottomResults.length) ? resIdx : 0;
      final resText = _resultTextSnapshot[startIdx] ?? (safeResIdx < viewModel.bottomResults.length ? viewModel.bottomResults[safeResIdx] : '');
      
      return ResultItem(emoji: p.emoji, name: p.displayName, color: p.color, text: resText);
    }).whereType<ResultItem>().toList();

    Navigator.of(context).push(MaterialPageRoute(builder: (context) => LadderResultScreen(results: results))).then((_) {
      _resetGameState();
    });
  }

  void _resetGameState() {
    if (!mounted) return;
    setState(() {
      for (var c in _activeControllers.values) {
        c.dispose();
      }
      _activeControllers.clear();
      _activeAnimations.clear();
      _finishedEndIndices.clear();
      _selectedStartIndices.clear();
      _endIndexSnapshot.clear();
      _resultTextSnapshot.clear();
      _isAnimating = false;
      _isNavigationTriggered = false;
    });
  }

  Future<void> _runAnimation(int index, LadderGameViewModel viewModel) async {
    if (_activeControllers.containsKey(index) || _isNavigationTriggered) return;
    final endIdx = viewModel.getResultIndex(index);
    _endIndexSnapshot[index] = endIdx;
    _resultTextSnapshot[index] = viewModel.bottomResults[endIdx];

    int ms = (12000 - (viewModel.speedLevel * 2000)).clamp(2000, 12000);
    final controller = AnimationController(vsync: this, duration: Duration(milliseconds: ms));
    final animation = CurvedAnimation(parent: controller, curve: Curves.easeInOutSine);

    setState(() {
      _activeControllers[index] = controller;
      _activeAnimations[index] = animation;
      _selectedStartIndices.add(index);
      _isAnimating = true;
    });

    try {
      await controller.forward().orCancel;
      if (!mounted) return;
      setState(() { _finishedEndIndices.add(endIdx); });
      if (_finishedEndIndices.length == _activeControllers.length) {
        SoundManager().playFanfare();
        await _shakeController?.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) _navigateToResults(viewModel);
      }
    } catch (e) {
      // Animation was cancelled or failed, no action needed for now
    }
  }

  void _startAll(LadderGameViewModel viewModel) async {
    if (_isNavigationTriggered) return;
    SoundManager().playSpark();
    for (int i = 0; i < viewModel.playerCount; i++) {
      final endIdx = viewModel.getResultIndex(i);
      _endIndexSnapshot[i] = endIdx;
      _resultTextSnapshot[i] = viewModel.bottomResults[endIdx];
    }
    List<Future> futures = [];
    for (int i = 0; i < viewModel.playerCount; i++) {
      futures.add(_runAnimation(i, viewModel));
    }
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LadderGameViewModel>();
    _updateControllers(viewModel);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 48,
        toolbarHeight: isLandscape ? 48 : 64,
        title: Text(
          '사다리 게임',
          style: GoogleFonts.plusJakartaSans(
            color: NeonColors.primary,
            fontSize: isLandscape ? 18 : 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: NeonColors.primary, size: isLandscape ? 20 : 22),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              SoundManager().playWoosh();
              viewModel.toggleShroudActive();
            },
            icon: Icon(viewModel.isShroudActive ? Icons.visibility_off : Icons.visibility,
              color: viewModel.isShroudActive ? const Color(0xFFBE2D06) : NeonColors.primary)),
          IconButton(
            onPressed: () {
              _resetGameState();
              viewModel.refreshLadder();
              for (int i = 0; i < viewModel.playerCount; i++) {
                _controllers[i].text = viewModel.bottomResults[i];
              }
            },
            icon: const Icon(Icons.refresh, color: NeonColors.primary)),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _shakeController!,
          builder: (context, child) {
            return Transform.translate(
              offset: _shakeAnimation!.value,
              child: child,
            );
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double totalW = constraints.maxWidth;
              final double gap = totalW / (viewModel.playerCount + 1);
              final double avatarSize = isLandscape ? (gap * 0.7).clamp(15.0, 45.0) : (gap * 0.9).clamp(20.0, 70.0);
              final double emojiSize = avatarSize * 0.6;
              final double resultSize = avatarSize;
              final double fontSize = (resultSize * 0.35).clamp(6.0, 14.0);
              final double topPadding = isLandscape ? 15.0 : 30.0;
              final double bottomGap = 5.0;
              final double ladderHeight = constraints.maxHeight - avatarSize - resultSize - topPadding - bottomGap - 10;
  
              return Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        // 사다리 렌더링 영역
                        Positioned(
                          top: topPadding + avatarSize,
                          left: 0, right: 0,
                          height: ladderHeight,
                          child: CustomPaint(
                            painter: LadderPainter(
                              playerCount: viewModel.playerCount,
                              sectionCount: viewModel.sectionCount,
                              ladderBars: viewModel.ladderBars,
                              activePathIndices: _activeAnimations.keys.toSet(),
                              animationMap: _activeAnimations,
                              participantColors: viewModel.currentParticipants.map((p) => p.color).toList(),
                              viewModel: viewModel,
                              ladderHeight: ladderHeight,
                            ),
                          ),
                        ),

                        // 상단 참가자 캐릭터
                        ...List.generate(viewModel.playerCount, (i) {
                          // Bounds check for participants
                          if (i >= viewModel.currentParticipants.length) return const SizedBox.shrink();
                          
                          final p = viewModel.currentParticipants[i];
                          final bool isSelected = _selectedStartIndices.contains(i);
                          return Positioned(
                            top: topPadding,
                            left: gap * (i + 1) - (avatarSize / 2),
                            child: GestureDetector(
                              onTap: () {
                                SoundManager().playTick();
                                _runAnimation(i, viewModel);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: avatarSize, height: avatarSize,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F6EE), // 파스텔 크림
                                  borderRadius: BorderRadius.circular(avatarSize * 0.4),
                                  border: Border.all(
                                    color: isSelected ? p.color : const Color(0xFFD4B483), // 나무 느낌 경계
                                    width: isSelected ? 3.5 : 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected ? p.color.withOpacity(0.5) : Colors.black.withOpacity(0.08),
                                      offset: Offset(0, isSelected ? 6 : 4),
                                      blurRadius: isSelected ? 12 : 6,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(p.emoji, style: TextStyle(fontSize: emojiSize)),
                              ),
                            ),
                          );
                        }),

                        // 하단 결과 뱃지
                        Positioned(
                          top: topPadding + avatarSize + ladderHeight - 2,
                          left: 0, right: 0,
                          child: SizedBox(
                            height: resultSize,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: List.generate(viewModel.playerCount, (i) {
                                final isTarget = _finishedEndIndices.contains(i);
                                
                                // Bounds check for result text
                                if (i >= viewModel.bottomResults.length) return const SizedBox.shrink();
                                
                                final resultText = viewModel.bottomResults[i];
                                final bool isWinMode = viewModel.currentMode == LadderGameMode.win;
                                final bool isTreatMode = viewModel.currentMode == LadderGameMode.treat;
                                final bool isOrderMode = viewModel.currentMode == LadderGameMode.order;
                                final bool isPass = (resultText.contains('통과') || resultText.contains('꽝') || resultText.contains('얻어먹기')) && !isOrderMode;
                                
                                // 결과 텍스트에서 이모지 제거 (정규식 사용)
                                final cleanResultText = resultText.replaceAll(RegExp(r'[\u{1f300}-\u{1f5ff}\u{1f600}-\u{1f64f}\u{1f680}-\u{1f6ff}\u{1f700}-\u{1f77f}\u{1f780}-\u{1f7ff}\u{1f800}-\u{1f8ff}\u{1f900}-\u{1f9ff}\u{1fa00}-\u{1faff}\u{2600}-\u{26ff}\u{2700}-\u{27bf}\u{fe00}-\u{fe0f}]', unicode: true), '');

                                Color statusColor;
                                if (isPass) {
                                  statusColor = const Color(0xFF8DAA5D); // 대나무 그린
                                } else if (isWinMode) {
                                  statusColor = const Color(0xFFD4B483); // 골드/우드
                                } else if (isTreatMode) {
                                  statusColor = const Color(0xFFE2725B); // 테라코타
                                } else if (isOrderMode) {
                                  statusColor = const Color(0xFF5D4037); // 다크 브라운
                                } else {
                                  statusColor = const Color(0xFFBE2D06);
                                }
  
                                return Positioned(
                                  left: gap * (i + 1) - (gap * 0.9 / 2),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: gap * 0.9, height: resultSize * 0.75,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(0xFFEFEBE9), // 아주 밝은 우드톤
                                      border: Border.all(
                                        color: isTarget ? statusColor : const Color(0xFFD7CCC8), 
                                        width: isTarget ? 3.5 : 2.5
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isTarget ? statusColor.withOpacity(0.4) : Colors.black.withOpacity(0.05),
                                          offset: const Offset(0, 4),
                                          blurRadius: isTarget ? 8 : 4,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: FittedBox(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                          child: Text(cleanResultText.trim(), textAlign: TextAlign.center,
                                            style: GoogleFonts.plusJakartaSans(
                                              color: isTarget ? statusColor : const Color(0xFF5D4037),
                                              fontSize: fontSize, 
                                              fontWeight: FontWeight.w900,
                                            )),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),

                        // 중앙 가림막 (Shroud) & 설정 패널
                        Positioned(
                          top: topPadding + avatarSize,
                          left: 0, right: 0,
                          height: ladderHeight,
                          child: IgnorePointer(
                            ignoring: _isAnimating,
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 650),
                                  curve: Curves.fastOutSlowIn,
                                  top: (viewModel.isShroudActive && !_isAnimating) ? 0 : -ladderHeight - 50,
                                  left: 0, right: 0,
                                  height: ladderHeight,
                                  child: Container(
                                    decoration: NeonTheme.getCardDecoration(radius: 32),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(32),
                                      child: CustomPaint(
                                        painter: _PatternPainter(color: const Color(0xFF8DAA5D).withOpacity(0.06)),
                                      ),
                                    ),
                                  ),
                                ),
                                if (viewModel.isShroudActive && !_isAnimating)
                                  Center(child: _configPanel(context, viewModel, ladderHeight)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _configPanel(BuildContext context, LadderGameViewModel viewModel, double ladderHeight) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('가로선 설정', 
            style: GoogleFonts.plusJakartaSans(
              color: NeonColors.textSub, 
              fontSize: isLandscape ? 12 : 14,
              fontWeight: FontWeight.bold,
            )),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onLongPress: () => _startStepping(false, viewModel),
                onLongPressUp: _stopStepping,
                child: Neon3DButton(
                  size: 40,
                  onPressed: () {
                    if (viewModel.sectionCount > 1) {
                      viewModel.setSectionCount(viewModel.sectionCount - 1);
                      _sectionCountController.text = '${viewModel.sectionCount}';
                      SoundManager().playTick();
                    }
                  },
                  child: const Icon(Icons.remove, color: Colors.white, size: 20),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: isLandscape ? 80 : 100,
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _sectionCountController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(
                      color: NeonColors.primary, 
                      fontWeight: FontWeight.w900, 
                      fontSize: isLandscape ? 28 : 40,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      final n = int.tryParse(val);
                      if (n != null && n >= 1 && n <= 100) {
                        viewModel.setSectionCount(n);
                      }
                    },
                    onSubmitted: (val) {
                      final n = int.tryParse(val);
                      if (n == null || n < 1) viewModel.setSectionCount(1);
                      if (n != null && n > 100) viewModel.setSectionCount(100);
                      _sectionCountController.text = '${viewModel.sectionCount}';
                    },
                  ),
                ),
              ),
              
              GestureDetector(
                onLongPress: () => _startStepping(true, viewModel),
                onLongPressUp: _stopStepping,
                child: Neon3DButton(
                  size: 40,
                  onPressed: () {
                    if (viewModel.sectionCount < 100) {
                      viewModel.setSectionCount(viewModel.sectionCount + 1);
                      _sectionCountController.text = '${viewModel.sectionCount}';
                      SoundManager().playTick();
                    }
                  },
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: isLandscape ? 160 : 200,
            child: Neon3DBigButton(
              label: 'START',
              onPressed: () => _startAll(viewModel),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;
  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    
    const double step = 20.0;
    for (double i = -size.height; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
