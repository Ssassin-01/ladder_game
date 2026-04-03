import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/neon_theme.dart';
import '../../core/neon_button.dart';
import 'ladder_game_mode.dart';
import 'ladder_game_screen.dart';
import 'ladder_game_view_model.dart';
import '../../core/sound_manager.dart';
import 'participant_manager_dialog.dart';

class LadderSettingsScreen extends StatefulWidget {
  final LadderGameMode mode;
  const LadderSettingsScreen({super.key, required this.mode});

  @override
  State<LadderSettingsScreen> createState() => _LadderSettingsScreenState();
}

class _LadderSettingsScreenState extends State<LadderSettingsScreen> {
  final List<TextEditingController> _penaltyControllers = [];
  late TextEditingController _playerCountController;
  Timer? _timer;
  bool _isLongPressing = false;
  DateTime _lastTapTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    final initialCount = context.read<LadderGameViewModel>().playerCount;
    _playerCountController = TextEditingController(
      text: initialCount.toString(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<LadderGameViewModel>();
      viewModel.setMode(widget.mode);
      _initControllers(viewModel.penaltyContents);
    });
  }

  void _initControllers(List<String> contents) {
    for (var controller in _penaltyControllers) {
      controller.dispose();
    }
    _penaltyControllers.clear();
    for (var content in contents) {
      _penaltyControllers.add(TextEditingController(text: content)..addListener(() => setState(() {})));
    }
    setState(() {});
  }

  bool _shouldProcessTap() {
    final now = DateTime.now();
    if (now.difference(_lastTapTime).inMilliseconds < 250) {
      return false;
    }
    _lastTapTime = now;
    return true;
  }

  void _startTimer(VoidCallback action) {
    _timer?.cancel();
    _isLongPressing = true;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      action();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    // 롱프레스 종료 후 약간의 지연을 두어 onTap이 바로 실행되지 않도록 함
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isLongPressing = false);
    });
  }

  void _addPenaltyField(int maxCount, {bool isManualMode = false, LadderGameViewModel? viewModel}) {
    if (isManualMode && viewModel != null) {
      if (viewModel.playerCount < 20) {
        viewModel.setPlayerCount(viewModel.playerCount + 1);
        _addController();
      } else {
        _stopTimer();
      }
      return;
    }

    if (_penaltyControllers.length < maxCount) {
      _addController();
    } else {
      _stopTimer();
    }
  }

  void _addController() {
    setState(() {
      _penaltyControllers.add(TextEditingController());
    });
  }

  void _removePenaltyField(int index, {bool isManualMode = false, LadderGameViewModel? viewModel}) {
    if (_penaltyControllers.length > 1) {
      if (isManualMode && viewModel != null) {
        if (viewModel.playerCount > 2) {
          viewModel.setPlayerCount(viewModel.playerCount - 1);
          _removeController(index);
        } else {
          _stopTimer();
        }
      } else {
        _removeController(index);
      }
    } else {
      _stopTimer();
    }
  }

  void _removeController(int index) {
    setState(() {
      _penaltyControllers[index].dispose();
      _penaltyControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    _stopTimer();
    _playerCountController.dispose();
    for (var controller in _penaltyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final viewModel = context.watch<LadderGameViewModel>();
    final isDarkMode = themeProvider.isDarkMode;
    final bool isOrderMode = widget.mode == LadderGameMode.order;
    final bool isManualMode = widget.mode == LadderGameMode.manual;
    final bool isTeamMode = widget.mode == LadderGameMode.team;
    final bool isDynamicMode = (widget.mode == LadderGameMode.penalty || 
                                widget.mode == LadderGameMode.win || 
                                widget.mode == LadderGameMode.treat) && !isOrderMode;

    // 플레이어 수 컨트롤러 동기화 (명단 불러오기 시 자동 반영)
    if (_playerCountController.text != viewModel.playerCount.toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playerCountController.text = viewModel.playerCount.toString();
      });
    }

    // 참가자 수에 맞춰 컨트롤러 개수 동기화
    if ((isDynamicMode || isManualMode) &&
        _penaltyControllers.length != (isManualMode ? viewModel.playerCount : _penaltyControllers.length)) {
      if (isManualMode && _penaltyControllers.length != viewModel.playerCount) {
        while (_penaltyControllers.length < viewModel.playerCount) {
          _penaltyControllers.add(TextEditingController()..addListener(() => setState(() {})));
        }
        while (_penaltyControllers.length > viewModel.playerCount) {
          _penaltyControllers.last.dispose();
          _penaltyControllers.removeLast();
        }
      }
    }

    if (isDynamicMode &&
        _penaltyControllers.length >= viewModel.playerCount) {
      int targetCount = viewModel.playerCount - 1;
      if (targetCount < 1) targetCount = 1;
      while (_penaltyControllers.length > targetCount) {
        _penaltyControllers.last.dispose();
        _penaltyControllers.removeLast();
      }
    }

    bool isStartButtonEnabled = true;
    if (isManualMode) {
      isStartButtonEnabled = _penaltyControllers.every((c) => c.text.trim().isNotEmpty);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDarkMode ? NeonColors.cyan : NeonColors.solidCyan,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.mode.label} 사다리 설정',
          style: TextStyle(
            color: isDarkMode ? NeonColors.cyan : NeonColors.solidCyan,
            shadows: isDarkMode ? NeonColors.getGlow(NeonColors.cyan) : null,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDarkMode ? NeonColors.hotPink : NeonColors.solidPink,
            ),
            onPressed: () {
              SoundManager().playTick();
              viewModel.resetSettings();
              
              // 텍스트 컨트롤러들도 초기화
              setState(() {
                for (var controller in _penaltyControllers) {
                  controller.dispose();
                }
                _penaltyControllers.clear();
                for (int i = 0; i < viewModel.penaltyCount; i++) {
                  _penaltyControllers.add(TextEditingController());
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildParticipantSection(viewModel, isDarkMode),
                    const SizedBox(height: 40),
  
                    if (isDynamicMode || isManualMode)
                      _buildPenaltySection(viewModel, isDarkMode),
                    
                    if (isTeamMode)
                      _buildTeamSection(viewModel, isDarkMode),
                    
                    const SizedBox(height: 10),
                    _sectionTitle(
                      '사다리 속도 (${viewModel.speedLevel}단계)',
                      isDarkMode ? NeonColors.limeGreen : NeonColors.solidGreen,
                      isDarkMode,
                    ),
                    Slider(
                      value: viewModel.speedLevel.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor:
                          isDarkMode
                              ? NeonColors.limeGreen
                              : NeonColors.solidGreen,
                      onChanged: (val) => viewModel.setSpeedLevel(val.toInt()),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: NeonButton(
              text: '게임 시작!',
              color: isStartButtonEnabled 
                  ? (isDarkMode ? NeonColors.limeGreen : NeonColors.solidGreen)
                  : Colors.grey,
              width: double.infinity,
              height: 56,
              onPressed: isStartButtonEnabled ? () {
                if (isDynamicMode || isManualMode) {
                  String defaultText = '벌칙';
                  if (widget.mode == LadderGameMode.win) {
                    defaultText = '당첨';
                  } else if (widget.mode == LadderGameMode.treat) {
                    defaultText = '내가 쏜다!';
                  } else if (widget.mode == LadderGameMode.manual) {
                    defaultText = '내용 없음';
                  }

                  final finalPenalties =
                      _penaltyControllers.map((c) {
                        final text = c.text.trim();
                        return text.isEmpty ? defaultText : text;
                      }).toList();
                  viewModel.setAllPenalties(finalPenalties);
                } else if (isOrderMode) {
                  // 순서 모드는 이미 viewModel.setMode 내에서 
                  // _generateResults를 통해 순번을 생성함
                }
                SoundManager().playFanfare();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LadderGameScreen(),
                  ),
                );
              } : null,
            ),
          ),
        ],
      ),
    );
  }

  // 팀 나누기 전용 설정 위젯
  Widget _buildTeamSection(LadderGameViewModel viewModel, bool isDarkMode) {
    final Color teamAccent = NeonColors.cyan;
    final int maxTeams = (viewModel.playerCount / 2).floor().clamp(2, 6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('팀 수 설정', isDarkMode ? teamAccent : NeonColors.solidCyan, isDarkMode),
        const SizedBox(height: 12),
        // 팀 수 선택 칩
        Wrap(
          spacing: 10,
          children: List.generate(maxTeams - 1, (i) {
            final teamNum = i + 2; // 2팀 ~ maxTeams哀
            final isSelected = viewModel.teamCount == teamNum;
            final teamColor = LadderGameViewModel.teamColors[i];
            return GestureDetector(
              onTap: () {
                SoundManager().playTick();
                viewModel.setTeamCount(teamNum);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? teamColor.withAlpha(80) : Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? teamColor : Colors.white24,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(color: teamColor.withAlpha(120), blurRadius: 8, spreadRadius: 1)
                  ] : [],
                ),
                child: Text(
                  '$teamNum팀',
                  style: TextStyle(
                    color: isSelected ? teamColor : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        // 팀장 유무 토글
        Row(
          children: [
            _sectionTitle('팀장 선정', isDarkMode ? NeonColors.electricYellow : NeonColors.solidYellow, isDarkMode),
            const Spacer(),
            Switch(
              value: viewModel.hasTeamLeader,
              onChanged: (val) {
                SoundManager().playTick();
                viewModel.setHasTeamLeader(val);
              },
              activeThumbColor: NeonColors.electricYellow,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParticipantSection(
    LadderGameViewModel viewModel,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        _sectionTitle(
          '참가자 수',
          isDarkMode ? NeonColors.electricYellow : NeonColors.solidYellow,
          isDarkMode,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _longPressCircleButton(
              Icons.remove_circle_outline,
              () {
                if (viewModel.playerCount > 2) {
                  viewModel.setPlayerCount(viewModel.playerCount - 1);
                  _playerCountController.text = viewModel.playerCount.toString();
                }
              },
              isDarkMode ? NeonColors.cyan : NeonColors.solidCyan,
              isDarkMode,
              size: 32,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _playerCountController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        int? count = int.tryParse(val);
                        if (count != null) {
                          viewModel.setPlayerCount(count.clamp(2, 20));
                        }
                      },
                      onSubmitted: (val) {
                        int count = (int.tryParse(val) ?? viewModel.playerCount)
                            .clamp(2, 20);
                        viewModel.setPlayerCount(count);
                        _playerCountController.text = count.toString();
                      },
                    ),
                  ),
                  Text(
                    '명',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            _longPressCircleButton(
              Icons.add_circle_outline,
              () {
                if (viewModel.playerCount < 20) {
                  viewModel.setPlayerCount(viewModel.playerCount + 1);
                  _playerCountController.text = viewModel.playerCount.toString();
                }
              },
              isDarkMode ? NeonColors.cyan : NeonColors.solidCyan,
              isDarkMode,
              size: 32,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "2명 ~ 20명 입력 가능",
          style: TextStyle(
            color: isDarkMode ? Colors.white38 : Colors.black38,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton.icon(
          onPressed: () {
            SoundManager().playTick();
            showDialog(
              context: context, 
              builder: (ctx) => const ParticipantManagerDialog()
            );
          },
          icon: Icon(Icons.people_alt, color: isDarkMode ? NeonColors.cyan : NeonColors.solidCyan),
          label: Text('명단 관리 (저장/불러오기)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode ? Colors.white10 : Colors.black12,
            foregroundColor: isDarkMode ? NeonColors.cyan : NeonColors.solidCyan,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildPenaltySection(LadderGameViewModel viewModel, bool isDarkMode) {
    final bool isWinMode = widget.mode == LadderGameMode.win;
    final bool isTreatMode = widget.mode == LadderGameMode.treat;
    final bool isManualMode = widget.mode == LadderGameMode.manual;
    
    Color accentColor;
    if (isWinMode) {
      accentColor = isDarkMode ? NeonColors.electricYellow : NeonColors.solidYellow;
    } else if (isTreatMode) {
      accentColor = Colors.orangeAccent;
    } else if (isManualMode) {
      accentColor = isDarkMode ? NeonColors.cyan : NeonColors.solidCyan;
    } else {
      accentColor = isDarkMode ? NeonColors.hotPink : NeonColors.solidPink;
    }
    
    String sectionTitleStr = '벌칙 설정';
    String hintTextStr = '벌칙을 입력해주세요';

    if (isWinMode) {
      sectionTitleStr = '당첨자 설정';
      hintTextStr = '당첨 내용(상품)을 입력하세요';
    } else if (isTreatMode) {
      sectionTitleStr = '쏘기(결제) 설정';
      hintTextStr = '무엇을 쏠지 입력하세요 (예: 커피, 밥)';
    } else if (isManualMode) {
      sectionTitleStr = '결과 직접 입력';
      hintTextStr = '내용을 입력해주세요';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle(sectionTitleStr, accentColor, isDarkMode),
            if (!isManualMode)
              _longPressCircleButton(
                Icons.add_circle,
                () => _addPenaltyField(viewModel.playerCount - 1),
                accentColor,
                isDarkMode,
              ),
            if (isManualMode)
              _longPressCircleButton(
                Icons.add_circle,
                () => _addPenaltyField(20, isManualMode: true, viewModel: viewModel),
                accentColor,
                isDarkMode,
              ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _penaltyControllers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _penaltyControllers[index],
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        prefixText: "${index + 1}. ",
                        prefixStyle: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                        hintText: hintTextStr,
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.white24 : Colors.black26,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor:
                            isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  if ((!isManualMode && _penaltyControllers.length > 1) || (isManualMode && _penaltyControllers.length > 2))
                    _longPressCircleButton(
                      Icons.remove_circle_outline,
                      () => _removePenaltyField(
                        index, 
                        isManualMode: isManualMode, 
                        viewModel: isManualMode ? viewModel : null
                      ),
                      Colors.redAccent,
                      isDarkMode,
                      size: 22,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, Color color, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        shadows: isDarkMode ? NeonColors.getGlow(color) : null,
      ),
    );
  }

  Widget _longPressCircleButton(
    IconData icon,
    VoidCallback action,
    Color color,
    bool isDarkMode, {
    double size = 28,
  }) {
    return GestureDetector(
      onTap: () {
        if (!_isLongPressing && _shouldProcessTap()) {
          SoundManager().playTick();
          action();
        }
      },
      onLongPressStart: (_) { SoundManager().playTick(); _startTimer(action); },
      onLongPressEnd: (_) => _stopTimer(),
      onLongPressCancel: () => _stopTimer(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}
