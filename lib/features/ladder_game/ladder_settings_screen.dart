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
    final viewModel = context.watch<LadderGameViewModel>();
    final bool isOrderMode = widget.mode == LadderGameMode.order;
    final bool isManualMode = widget.mode == LadderGameMode.manual;
    final bool isTeamMode = widget.mode == LadderGameMode.team;
    final bool isDynamicMode = (widget.mode == LadderGameMode.penalty || 
                                widget.mode == LadderGameMode.win || 
                                widget.mode == LadderGameMode.treat) && !isOrderMode;

    if (_playerCountController.text != viewModel.playerCount.toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playerCountController.text = viewModel.playerCount.toString();
      });
    }

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
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: NeonColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.mode.label} 설정',
          style: const TextStyle(
            color: NeonColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: NeonColors.secondary),
            onPressed: () {
              SoundManager().playTick();
              viewModel.resetSettings();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  _buildParticipantSection(viewModel),
                  const SizedBox(height: 32),
                  if (isDynamicMode || isManualMode)
                    _buildPenaltySection(viewModel),
                  if (isTeamMode)
                    _buildTeamSection(viewModel),
                  const SizedBox(height: 10),
                  _sectionTitle('동작 속도 (${viewModel.speedLevel}단계)', NeonColors.primary),
                  Slider(
                    value: viewModel.speedLevel.toDouble(),
                    min: 1, max: 5, divisions: 4,
                    activeColor: NeonColors.primary,
                    inactiveColor: NeonColors.primary.withOpacity(0.1),
                    onChanged: (val) => viewModel.setSpeedLevel(val.toInt()),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: NeonButton(
              text: '게임 시작',
              color: isStartButtonEnabled ? NeonColors.primary : Colors.grey[400]!,
              width: double.infinity,
              height: 60,
              onPressed: isStartButtonEnabled ? () {
                if (isDynamicMode || isManualMode) {
                  String defaultText = '벌칙';
                  if (widget.mode == LadderGameMode.win) {
                    defaultText = '당첨';
                  } else if (widget.mode == LadderGameMode.treat) {
                    defaultText = '내가 쏜다';
                  } else if (widget.mode == LadderGameMode.manual) {
                    defaultText = '내용 없음';
                  }

                  final finalPenalties =
                      _penaltyControllers.map((c) {
                        final text = c.text.trim();
                        return text.isEmpty ? defaultText : text;
                      }).toList();
                  viewModel.setAllPenalties(finalPenalties);
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

  Widget _buildTeamSection(LadderGameViewModel viewModel) {
    const Color teamAccent = NeonColors.secondary;
    final int maxTeams = (viewModel.playerCount / 2).floor().clamp(2, 6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('팀 수 설정', teamAccent),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(maxTeams - 1, (i) {
            final teamNum = i + 2;
            final isSelected = viewModel.teamCount == teamNum;
            final teamColor = LadderGameViewModel.teamColors[i];
            return GestureDetector(
              onTap: () {
                SoundManager().playTick();
                viewModel.setTeamCount(teamNum);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? teamColor.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? teamColor : NeonColors.textSub.withOpacity(0.1),
                    width: isSelected ? 2 : 1.5,
                  ),
                ),
                child: Text(
                  '$teamNum팀',
                  style: TextStyle(
                    color: isSelected ? teamColor : NeonColors.textSub,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _sectionTitle('팀장 선정', NeonColors.primary),
            const Spacer(),
            Switch(
              value: viewModel.hasTeamLeader,
              onChanged: (val) {
                SoundManager().playTick();
                viewModel.setHasTeamLeader(val);
              },
              activeColor: NeonColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParticipantSection(LadderGameViewModel viewModel) {
    return Column(
      children: [
        _sectionTitle('참가자 수', NeonColors.primary),
        const SizedBox(height: 16),
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
              NeonColors.primary,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: NeonColors.textMain,
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
                    ),
                  ),
                  const Text(
                    '명',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: NeonColors.textSub,
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
              NeonColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text("2명 ~ 20명까지 설정 가능", style: TextStyle(color: NeonColors.textSub, fontSize: 13)),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () {
            SoundManager().playTick();
            showDialog(
              context: context, 
              builder: (ctx) => const ParticipantManagerDialog()
            );
          },
          icon: const Icon(Icons.people_alt, size: 20),
          label: const Text('명단 관리', style: TextStyle(fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            foregroundColor: NeonColors.primary,
            side: BorderSide(color: NeonColors.primary.withOpacity(0.2)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPenaltySection(LadderGameViewModel viewModel) {
    final bool isWinMode = widget.mode == LadderGameMode.win;
    final bool isTreatMode = widget.mode == LadderGameMode.treat;
    final bool isManualMode = widget.mode == LadderGameMode.manual;
    
    Color accentColor = isWinMode ? Colors.amber[700]! : (isTreatMode ? Colors.orange : NeonColors.primary);
    String sectionTitleStr = isWinMode ? '당첨자 설정' : (isTreatMode ? '결제자 설정' : '벌칙 설정');
    String hintTextStr = isWinMode ? '당첨 내용을 입력하세요' : (isTreatMode ? '무엇을 쏠까요?' : '벌칙을 입력해주세요');

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle(sectionTitleStr, accentColor),
            _longPressCircleButton(
              Icons.add_circle,
              () => _addPenaltyField(isManualMode ? 20 : viewModel.playerCount - 1, isManualMode: isManualMode, viewModel: isManualMode ? viewModel : null),
              accentColor,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _penaltyControllers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _penaltyControllers[index],
                      style: const TextStyle(color: NeonColors.textMain, fontSize: 15),
                      decoration: InputDecoration(
                        prefixText: "${index + 1}. ",
                        prefixStyle: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                        hintText: hintTextStr,
                        hintStyle: TextStyle(color: NeonColors.textSub.withValues(alpha: 0.4)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: NeonColors.textSub.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: NeonColors.textSub.withValues(alpha: 0.1)),
                        ),
                      ),
                    ),
                  ),
                  if ((!isManualMode && _penaltyControllers.length > 1) || (isManualMode && _penaltyControllers.length > 2))
                    _longPressCircleButton(
                      Icons.remove_circle,
                      () => _removePenaltyField(index, isManualMode: isManualMode, viewModel: isManualMode ? viewModel : null),
                      Colors.grey[400]!,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _longPressCircleButton(IconData icon, VoidCallback action, Color color, {double size = 30}) {
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
