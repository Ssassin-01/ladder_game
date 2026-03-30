import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

class _LadderGameScreenState extends State<LadderGameScreen>
    with TickerProviderStateMixin {
  AnimationController? _shakeController;
  Animation<Offset>? _shakeAnimation;

  final Map<int, AnimationController> _activeControllers = {};
  final Map<int, Animation<double>> _activeAnimations = {};
  final Set<int> _finishedEndIndices = {};
  final Set<int> _selectedStartIndices = {};

  // 데이터 불일치 방지를 위한 스냅샷
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
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0.01, 0)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.01, 0), end: const Offset(-0.01, 0)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-0.01, 0), end: Offset.zero),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(parent: _shakeController!, curve: Curves.linear),
    );
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
          _controllers.add(
            TextEditingController(text: viewModel.bottomResults[i]),
          );
        }
      }
    }

    // 새로고침 등으로 데이터가 바뀌었을 때 (애니메이션 중이 아닐 때만) 동기화
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
    if (!mounted || _selectedStartIndices.isEmpty || _isNavigationTriggered)
      return;

    _isNavigationTriggered = true;

    // 스냅샷된 결과를 사용하여 데이터 불일치 완전 차단
    final results =
        _selectedStartIndices.map((startIdx) {
          final p = viewModel.currentParticipants[startIdx];
          final resIdx =
              _endIndexSnapshot[startIdx] ?? viewModel.getResultIndex(startIdx);
          final resText =
              _resultTextSnapshot[startIdx] ?? viewModel.bottomResults[resIdx];

          return ResultItem(
            emoji: p.emoji,
            name: p.animalType,
            color: p.color,
            text: resText,
          );
        }).toList();

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => LadderResultScreen(results: results),
          ),
        )
        .then((_) {
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

    // 애니메이션 시작 시점에 결과 스냅샷 생성 (데이터 불일치 방지 핵심)
    final endIdx = viewModel.getResultIndex(index);
    _endIndexSnapshot[index] = endIdx;
    _resultTextSnapshot[index] = viewModel.bottomResults[endIdx];

    int ms = (12000 - (viewModel.speedLevel * 2000)).clamp(2000, 12000);
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    );

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutSine,
    );

    setState(() {
      _activeControllers[index] = controller;
      _activeAnimations[index] = animation;
      _selectedStartIndices.add(index);
      _isAnimating = true;
    });

    try {
      await controller.forward().orCancel;
      if (!mounted) return;

      setState(() {
        _finishedEndIndices.add(endIdx);
      });

      if (_finishedEndIndices.length == _activeControllers.length) {
        await _shakeController?.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          _navigateToResults(viewModel);
        }
      }
    } catch (e) {}
  }

  void _startAll(LadderGameViewModel viewModel) async {
    if (_isNavigationTriggered) return;

    // 모든 참가자에 대해 미리 결과 스냅샷 설정
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
    _autoIncrementTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      int minLines = (viewModel.playerCount * 1.2).ceil().clamp(5, 100);
      if (increment) {
        if (viewModel.sectionCount < 100)
          viewModel.setSectionCount(viewModel.sectionCount + 1);
      } else {
        if (viewModel.sectionCount > minLines)
          viewModel.setSectionCount(viewModel.sectionCount - 1);
      }
    });
  }

  void _stopAutoIncrement() {
    _autoIncrementTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LadderGameViewModel>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    _updateControllers(viewModel);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: isLandscape ? 40 : 56,
        title: Text(
          '사다리 게임',
          style: TextStyle(
            color: isDarkMode ? NeonColors.cyan : NeonColors.solidCyan,
            fontSize: isLandscape ? 18 : 20,
            shadows: isDarkMode ? NeonColors.getGlow(NeonColors.cyan) : null,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDarkMode ? NeonColors.cyan : NeonColors.solidCyan,
            size: isLandscape ? 20 : 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => viewModel.toggleShroudActive(),
            icon: Icon(
              viewModel.isShroudActive
                  ? Icons.visibility_off
                  : Icons.visibility,
              color:
                  viewModel.isShroudActive
                      ? NeonColors.hotPink
                      : NeonColors.limeGreen,
            ),
            tooltip: '가림막 켜기/끄기',
          ),
          IconButton(
            onPressed: () {
              _resetGameState();
              viewModel.refreshLadder();
              // 텍스트 컨트롤러 강제 업데이트
              for (int i = 0; i < viewModel.playerCount; i++) {
                _controllers[i].text = viewModel.bottomResults[i];
              }
            },
            icon: Icon(
              Icons.refresh,
              color: isDarkMode ? NeonColors.limeGreen : NeonColors.solidGreen,
            ),
            tooltip: '사다리 섞기',
          ),
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: isDarkMode ? NeonColors.cyan : NeonColors.solidCyan,
              size: isLandscape ? 20 : 24,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double totalW = constraints.maxWidth;
            final double gap = totalW / (viewModel.playerCount + 1);
            final double avatarSize =
                isLandscape
                    ? (gap * 0.7).clamp(15.0, 45.0)
                    : (gap * 0.9).clamp(20.0, 70.0);
            final double emojiSize = avatarSize * 0.6;
            final double resultSize = avatarSize;
            final double fontSize = (resultSize * 0.35).clamp(6.0, 14.0);

            final double topPadding = isLandscape ? 15.0 : 30.0;
            final double bottomGap = 5.0;
            final double ladderHeight =
                constraints.maxHeight -
                avatarSize -
                resultSize -
                topPadding -
                bottomGap -
                10;

            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // 1. 사다리 메인 영역
                      Positioned(
                        top: topPadding + avatarSize,
                        left: 0,
                        right: 0,
                        height:
                            ladderHeight + (resultSize / 2), // 결과 원 중앙까지 캔버스 확장
                        child: CustomPaint(
                          painter: LadderPainter(
                            playerCount: viewModel.playerCount,
                            sectionCount: viewModel.sectionCount,
                            ladderBars: viewModel.ladderBars,
                            activePathIndices: _activeControllers.keys.toSet(),
                            animationMap: _activeAnimations,
                            viewModel: viewModel,
                            participantColors:
                                viewModel.currentParticipants
                                    .map((p) => p.color)
                                    .toList(),
                            isDarkMode: isDarkMode,
                            ladderHeight: ladderHeight,
                          ),
                        ),
                      ),
                      // 2. 동물 프로필 (상단)
                      ...List.generate(viewModel.playerCount, (i) {
                        final p = viewModel.currentParticipants[i];
                        return Positioned(
                          top: topPadding,
                          left: gap * (i + 1) - (avatarSize / 2),
                          child: GestureDetector(
                            onTap: () => _runAnimation(i, viewModel),
                            child: Container(
                              width: avatarSize,
                              height: avatarSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                border: Border.all(
                                  color:
                                      _selectedStartIndices.contains(i)
                                          ? p.color
                                          : p.color.withOpacity(0.4),
                                  width: 2,
                                ),
                                boxShadow:
                                    isDarkMode &&
                                            _selectedStartIndices.contains(i)
                                        ? [
                                          BoxShadow(
                                            color: p.color.withOpacity(0.5),
                                            blurRadius: 8,
                                          ),
                                        ]
                                        : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                p.emoji,
                                style: TextStyle(fontSize: emojiSize),
                              ),
                            ),
                          ),
                        );
                      }),
                      // 3. 하단 결과 원
                      Positioned(
                        top: topPadding + avatarSize + ladderHeight - 2,
                        left: 0,
                        right: 0,
                        child: SizedBox(
                          height: resultSize,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: List.generate(viewModel.playerCount, (i) {
                              final isTarget = _finishedEndIndices.contains(i);
                              final resultText = _controllers[i].text;
                              final bool isPenalty = resultText.contains('당첨');
                              final Color statusColor =
                                  isPenalty
                                      ? (isDarkMode
                                          ? NeonColors.hotPink
                                          : NeonColors.solidPink)
                                      : (isDarkMode
                                          ? NeonColors.limeGreen
                                          : NeonColors.solidGreen);

                              return Positioned(
                                left: gap * (i + 1) - (resultSize / 2),
                                child: Container(
                                  width: resultSize,
                                  height: resultSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        isDarkMode
                                            ? Colors.black87
                                            : Colors.white,
                                    border: Border.all(
                                      color:
                                          isTarget
                                              ? statusColor
                                              : statusColor.withOpacity(0.3),
                                      width: 2.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: TextField(
                                      textAlign: TextAlign.center,
                                      controller: _controllers[i],
                                      onChanged:
                                          (val) =>
                                              viewModel.updateResult(i, val),
                                      style: TextStyle(
                                        color:
                                            isTarget
                                                ? statusColor
                                                : (isDarkMode
                                                    ? Colors.white
                                                    : Colors.black87),
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        counterText: '',
                                        alignLabelWithHint: true,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),

                      // 4. 가림막(Fog) 및 중앙 제어 UI
                      Positioned(
                        top: topPadding + avatarSize + 20,
                        left: 0,
                        right: 0,
                        height: ladderHeight - 40,
                        child: IgnorePointer(
                          ignoring: _isAnimating,
                          child: Stack(
                            children: [
                              // 가림막 (Blur + 낮은 불투명도 + 테두리)
                              Positioned.fill(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 400),
                                  opacity:
                                      (viewModel.isShroudActive &&
                                              !_isAnimating)
                                          ? 1.0
                                          : 0.0,
                                  child: ClipRect(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color:
                                              isDarkMode
                                                  ? Colors.black.withOpacity(
                                                    0.95,
                                                  )
                                                  : Colors.white.withOpacity(
                                                    0.95,
                                                  ),
                                          border: Border.all(
                                            color:
                                                isDarkMode
                                                    ? NeonColors.cyan
                                                    : NeonColors.solidCyan,
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // 중앙 제어 UI (게임 시작 전에만 보임)
                              if (!_isAnimating)
                                Center(
                                  child: _configPanel(viewModel, isDarkMode),
                                ),
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
    );
  }

  Widget _configPanel(LadderGameViewModel viewModel, bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '가로선: ${viewModel.sectionCount}',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _smallCircleButton(
              '-',
              () {
                int minLines = (viewModel.playerCount * 1.2).ceil().clamp(
                  5,
                  100,
                );
                if (viewModel.sectionCount > minLines)
                  viewModel.setSectionCount(viewModel.sectionCount - 1);
              },
              isDarkMode,
              onLongPress: () => _startAutoIncrement(false, viewModel),
              onLongPressEnd: _stopAutoIncrement,
            ),
            const SizedBox(width: 40),
            _smallCircleButton(
              '+',
              () {
                if (viewModel.sectionCount < 100)
                  viewModel.setSectionCount(viewModel.sectionCount + 1);
              },
              isDarkMode,
              onLongPress: () => _startAutoIncrement(true, viewModel),
              onLongPressEnd: _stopAutoIncrement,
            ),
          ],
        ),
        const SizedBox(height: 25),
        NeonButton(
          text: 'START',
          width: 140,
          height: 45,
          color: isDarkMode ? NeonColors.hotPink : const Color(0xFF1A237E),
          onPressed: () => _startAll(viewModel),
        ),
      ],
    );
  }

  Widget _smallCircleButton(
    String text,
    VoidCallback onPressed,
    bool isDarkMode, {
    VoidCallback? onLongPress,
    VoidCallback? onLongPressEnd,
  }) {
    final color = isDarkMode ? NeonColors.cyan : NeonColors.solidCyan;
    return GestureDetector(
      onLongPressStart: (_) => onLongPress?.call(),
      onLongPressEnd: (_) => onLongPressEnd?.call(),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
