import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/neon_theme.dart';
import '../../core/neon_button.dart';
import 'ladder_game_mode.dart';
import 'ladder_game_view_model.dart';
import 'ladder_painter.dart';
import 'ladder_result_screen.dart';
import '../../core/sound_manager.dart';

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

  Timer? _autoIncrementTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LadderGameViewModel>().resetShroud();
    });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(0.01, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.01, 0), end: const Offset(-0.01, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.01, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController!, curve: Curves.linear));
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
          _controllers.add(TextEditingController(text: viewModel.bottomResults[i]));
        }
      }
    }
    if (!_isAnimating) {
      for (int i = 0; i < viewModel.playerCount; i++) {
        if (_controllers[i].text != viewModel.bottomResults[i]) {
          _controllers[i].text = viewModel.bottomResults[i];
        }
      }
    }
  }

  @override
  void dispose() {
    _autoIncrementTimer?.cancel();
    _shakeController?.dispose();
    for (var c in _activeControllers.values) {
      c.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _navigateToResults(LadderGameViewModel viewModel) {
    if (!mounted || _selectedStartIndices.isEmpty || _isNavigationTriggered) return;
    _isNavigationTriggered = true;

    final results = _selectedStartIndices.map((startIdx) {
      final p = viewModel.currentParticipants[startIdx];
      final resIdx = _endIndexSnapshot[startIdx] ?? viewModel.getResultIndex(startIdx);
      final resText = _resultTextSnapshot[startIdx] ?? viewModel.bottomResults[resIdx];
      return ResultItem(emoji: p.emoji, name: p.displayName, color: p.color, text: resText);
    }).toList();

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

  void _startAutoIncrement(bool increment, LadderGameViewModel viewModel) {
    _autoIncrementTimer?.cancel();
    _autoIncrementTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (increment) {
        if (viewModel.sectionCount < 100) viewModel.setSectionCount(viewModel.sectionCount + 1);
      } else {
        if (viewModel.sectionCount > 1) viewModel.setSectionCount(viewModel.sectionCount - 1);
      }
    });
  }

  void _stopAutoIncrement() {
    _autoIncrementTimer?.cancel();
  }

  void _showEditResultDialog(BuildContext context, int index, LadderGameViewModel viewModel) {
    final controller = TextEditingController(text: viewModel.bottomResults[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('결과 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '결과를 입력하세요'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              viewModel.updateResult(index, controller.text);
              _controllers[index].text = controller.text;
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // --- 가로선 갯수 직접 입력 다이얼로그 추가 ---
  void _showSectionCountDialog(BuildContext context, LadderGameViewModel viewModel) {
    final controller = TextEditingController(text: viewModel.sectionCount.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가로선 갯수 설정'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: '1 ~ 100 사이 숫자 입력'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              int val = int.tryParse(controller.text) ?? viewModel.sectionCount;
              viewModel.setSectionCount(val.clamp(1, 100));
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
        toolbarHeight: isLandscape ? 40 : 56,
        title: Text('사다리 게임',
          style: TextStyle(
            color: NeonColors.primary,
            fontSize: isLandscape ? 18 : 20,
          )),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: NeonColors.primary, size: isLandscape ? 20 : 24),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => viewModel.toggleShroudActive(),
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
          animation: _shakeAnimation!,
          builder: (context, child) {
            return Transform.translate(
              offset: _shakeAnimation!.value * MediaQuery.of(context).size.width,
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
                        Positioned(
                          top: topPadding + avatarSize,
                          left: 0, right: 0,
                          height: ladderHeight + (resultSize / 2),
                          child: CustomPaint(
                            painter: LadderPainter(
                              playerCount: viewModel.playerCount,
                              sectionCount: viewModel.sectionCount,
                              ladderBars: viewModel.ladderBars,
                              activePathIndices: _activeControllers.keys.toSet(),
                              participantColors: viewModel.currentParticipants.map((p) => p.color).toList(),
                              animationMap: _activeAnimations,
                              viewModel: viewModel,
                              ladderHeight: ladderHeight,
                            ),
                          ),
                        ),
                        ...List.generate(viewModel.playerCount, (i) {
                          final p = viewModel.currentParticipants[i];
                          return Positioned(
                            top: topPadding,
                            left: gap * (i + 1) - (avatarSize / 2),
                            child: GestureDetector(
                              onTap: () => _runAnimation(i, viewModel),
                              child: Container(
                                width: avatarSize, height: avatarSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFF9F7F2),
                                  border: Border.all(color: _selectedStartIndices.contains(i) ? p.color : p.color.withOpacity(0.4), width: 2),
                                  boxShadow: _selectedStartIndices.contains(i) ? [BoxShadow(color: p.color.withOpacity(0.5), blurRadius: 8)] : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(p.emoji, style: TextStyle(fontSize: emojiSize)),
                              ),
                            ),
                          );
                        }),
                        Positioned(
                          top: topPadding + avatarSize + ladderHeight - 2,
                          left: 0, right: 0,
                          child: SizedBox(
                            height: resultSize,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: List.generate(viewModel.playerCount, (i) {
                                final isTarget = _finishedEndIndices.contains(i);
                                final resultText = viewModel.bottomResults[i];
                                
                                final bool isWinMode = viewModel.currentMode == LadderGameMode.win;
                                final bool isTreatMode = viewModel.currentMode == LadderGameMode.treat;
                                final bool isOrderMode = viewModel.currentMode == LadderGameMode.order;
                                final bool isPass = (resultText.contains('통과') || resultText.contains('꽝') || resultText.contains('얻어먹기')) && !isOrderMode;
                                
                                Color statusColor;
                                if (isPass) {
                                  statusColor = NeonColors.primary;
                                } else {
                                  if (isWinMode) {
                                    statusColor = Colors.amber;
                                  } else if (isTreatMode) {
                                    statusColor = Colors.orange;
                                  } else if (isOrderMode) {
                                    statusColor = NeonColors.primary;
                                  } else {
                                    statusColor = const Color(0xFFBE2D06);
                                  }
                                }
  
                                return Positioned(
                                  left: gap * (i + 1) - (gap * 0.9 / 2),
                                  child: GestureDetector(
                                    onTap: isOrderMode ? null : () => _showEditResultDialog(context, i, viewModel),
                                    child: Container(
                                      width: gap * 0.9, height: resultSize * 0.75,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(resultSize * 0.35),
                                        color: Colors.white,
                                        border: Border.all(
                                          color: isTarget ? statusColor : statusColor.withOpacity(0.3), 
                                          width: (!isPass || isOrderMode) ? 3.0 : 2.5
                                        ),
                                        boxShadow: (!isPass || isOrderMode) && isTarget 
                                            ? [BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)] 
                                            : null,
                                      ),
                                      child: Center(
                                        child: FittedBox(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                            child: Text(resultText, textAlign: TextAlign.center,
                                              style: TextStyle(color: isTarget ? statusColor : NeonColors.textMain,
                                                fontSize: fontSize, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        Positioned(
                          top: topPadding + avatarSize + 20,
                          left: 0, right: 0,
                          height: ladderHeight - 40,
                          child: IgnorePointer(
                            ignoring: _isAnimating,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 400),
                                    opacity: (viewModel.isShroudActive && !_isAnimating) ? 1.0 : 0.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.95),
                                        border: Border.all(color: NeonColors.primary, width: 3),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                                if (!_isAnimating)
                                  Center(child: _configPanel(context, viewModel)),
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

  Widget _configPanel(BuildContext context, LadderGameViewModel viewModel) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('가로선 (터치하여 직접 수정)', 
            style: TextStyle(color: NeonColors.textSub, fontSize: isLandscape ? 12 : 14)),
          SizedBox(height: isLandscape ? 8 : 15),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _smallCircleButton('-', () {
                SoundManager().playTick();
                if (viewModel.sectionCount > 1) viewModel.setSectionCount(viewModel.sectionCount - 1);
              }, onLongPress: () => _startAutoIncrement(false, viewModel), onLongPressEnd: _stopAutoIncrement),
              
              SizedBox(width: isLandscape ? 15 : 25),
              
              // 중앙 숫자 텍스트 (터치 가능하게)
              InkWell(
                onTap: () => _showSectionCountDialog(context, viewModel),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isLandscape ? 10 : 15, vertical: 5),
                      child: Text('${viewModel.sectionCount}줄',
                    style: TextStyle(color: NeonColors.textMain, fontWeight: FontWeight.bold, fontSize: isLandscape ? 22 : 28)),
                ),
              ),
              
              SizedBox(width: isLandscape ? 15 : 25),
              
              _smallCircleButton('+', () {
                SoundManager().playTick();
                if (viewModel.sectionCount < 100) viewModel.setSectionCount(viewModel.sectionCount + 1);
              }, onLongPress: () => _startAutoIncrement(true, viewModel), onLongPressEnd: _stopAutoIncrement),
            ],
          ),
          SizedBox(height: isLandscape ? 12 : 25),
          NeonButton(
            text: 'START',
            width: isLandscape ? 120 : 140,
            height: isLandscape ? 38 : 45,
            color: NeonColors.primary,
            onPressed: () => _startAll(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _smallCircleButton(String text, VoidCallback onPressed, {VoidCallback? onLongPress, VoidCallback? onLongPressEnd}) {
    const color = NeonColors.primary;
    return GestureDetector(
      onLongPressStart: (_) => onLongPress?.call(),
      onLongPressEnd: (_) => onLongPressEnd?.call(),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 45, height: 45,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
          alignment: Alignment.center,
          child: Text(text, style: const TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
