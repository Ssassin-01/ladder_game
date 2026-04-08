import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/neon_theme.dart';
import '../../core/widgets/neon_3d_button.dart';
import 'ladder_game_mode.dart';
import 'ladder_game_view_model.dart';
import 'ladder_game_screen.dart';
import 'participant_manager_dialog.dart';

class LadderSettingsScreen extends StatefulWidget {
  final LadderGameMode mode;

  const LadderSettingsScreen({super.key, required this.mode});

  @override
  State<LadderSettingsScreen> createState() => _LadderSettingsScreenState();
}

class _LadderSettingsScreenState extends State<LadderSettingsScreen> {
  final List<TextEditingController> _itemControllers = [];
  final TextEditingController _playerCountController = TextEditingController();
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<LadderGameViewModel>();
      viewModel.setMode(widget.mode);
      if (mounted) {
        setState(() {
          _syncControllersWithViewModel(viewModel);
          _playerCountController.text = '${viewModel.playerCount}';
        });
      }
    });
  }

  void _syncControllersWithViewModel(LadderGameViewModel viewModel) {
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    _itemControllers.clear();
    
    for (var item in viewModel.penaltyContents) {
      _itemControllers.add(TextEditingController(text: item));
    }
    _playerCountController.text = '${viewModel.playerCount}';
  }

  void _startStepping(bool isIncrement, LadderGameViewModel viewModel) {
    _stopStepping();
    final action = () {
      if (isIncrement) {
        if (viewModel.playerCount < 20) {
          viewModel.setPlayerCount(viewModel.playerCount + 1);
          _syncControllersWithViewModel(viewModel);
        }
      } else {
        if (viewModel.playerCount > 2) {
          viewModel.setPlayerCount(viewModel.playerCount - 1);
          _syncControllersWithViewModel(viewModel);
        }
      }
    };
    action();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 200), (_) => action());
  }

  void _stopStepping() {
    _stepTimer?.cancel();
    _stepTimer = null;
  }

  @override
  void dispose() {
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    _playerCountController.dispose();
    _stopStepping();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LadderGameViewModel>();
    final String title = _getModeTitle(widget.mode);

    // Ensure player count controller is in sync with VM (e.g. after mode change)
    if (_playerCountController.text != viewModel.playerCount.toString()) {
      _playerCountController.text = viewModel.playerCount.toString();
    }

    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: _buildAppBar(context, title, viewModel),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Column(
                children: [
                  // 1. Participant Count Card
                  _buildParticipantCard(viewModel),
                  const SizedBox(height: 20),

                  // 2. Ladder Speed Card (Order: Conditional based on mode)
                  if (widget.mode != LadderGameMode.team) ...[
                    _buildSpeedCard(viewModel),
                    const SizedBox(height: 20),
                  ],

                  // 3. Mode Specific Content (The 3rd card in the sequence)
                  _buildModeSpecificCard(viewModel),
                  
                  if (widget.mode == LadderGameMode.team) ...[
                    const SizedBox(height: 20),
                    _buildSpeedCard(viewModel),
                  ],
                  
                  const SizedBox(height: 32),

                  Builder(
                    builder: (context) {
                      final bool isManualMode = widget.mode == LadderGameMode.manual;
                      bool canStart = true;
                      
                      // Validation for Manual Mode
                      if (isManualMode) {
                        for (var controller in _itemControllers) {
                          if (controller.text.trim().isEmpty) {
                            canStart = false;
                            break;
                          }
                        }
                      }

                      return Neon3DBigButton(
                        label: '게임 시작',
                        onPressed: canStart ? () {
                          _applyAllChanges(viewModel);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LadderGameScreen()),
                          );
                        } : null,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 60),

              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String title, LadderGameViewModel viewModel) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: NeonColors.primary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: NeonColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            viewModel.resetSettings();
            _syncControllersWithViewModel(viewModel);
            setState(() {});
          },
          icon: const Icon(Icons.restart_alt, size: 18, color: NeonColors.primary),
          label: Text(
            '초기화',
            style: GoogleFonts.plusJakartaSans(
              color: NeonColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildParticipantCard(LadderGameViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: NeonTheme.getCardDecoration(bg: const Color(0xFFF5F4EB)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: NeonColors.pointPink, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.groups, size: 22, color: NeonColors.shadow),
                  ),
                  const SizedBox(width: 14),
                  Text('참가자 수', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: NeonColors.primary)),
                ],
              ),
              Neon3DButton(
                size: 44,
                baseColor: NeonColors.pointPink,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ParticipantManagerDialog(),
                  );
                },
                child: const Icon(Icons.inventory, size: 18, color: NeonColors.shadow),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onLongPress: () => _startStepping(false, viewModel),
                onLongPressUp: _stopStepping,
                child: Neon3DButton(
                  size: 52,
                  onPressed: () {
                    if (viewModel.playerCount > 2) {
                      viewModel.setPlayerCount(viewModel.playerCount - 1);
                      _syncControllersWithViewModel(viewModel);
                    }
                  },
                  child: const Icon(Icons.remove, color: Colors.white, size: 24),
                ),
              ),
              Container(
                width: 100,
                alignment: Alignment.center,
                child: TextField(
                  controller: _playerCountController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 52, 
                    fontWeight: FontWeight.w900,
                    color: NeonColors.primary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    final n = int.tryParse(val);
                    if (n != null) {
                      if (n >= 2 && n <= 20) {
                        viewModel.setPlayerCount(n);
                      }
                    }
                  },
                  onSubmitted: (val) {
                    final n = int.tryParse(val);
                    if (n == null || n < 2) viewModel.setPlayerCount(2);
                    if (n != null && n > 20) viewModel.setPlayerCount(20);
                    _syncControllersWithViewModel(viewModel);
                  },
                ),
              ),
              GestureDetector(
                onLongPress: () => _startStepping(true, viewModel),
                onLongPressUp: _stopStepping,
                child: Neon3DButton(
                  size: 52,
                  onPressed: () {
                    if (viewModel.playerCount < 20) {
                      viewModel.setPlayerCount(viewModel.playerCount + 1);
                      _syncControllersWithViewModel(viewModel);
                    }
                  },
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedCard(LadderGameViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: NeonTheme.getCardDecoration(bg: const Color(0xFFFEFCF4)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: NeonColors.pointGreen, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.speed, size: 22, color: NeonColors.primary),
              ),
              const SizedBox(width: 14),
              Text('사다리 속도', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: NeonColors.primary)),
            ],
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: NeonColors.pointGreen,
              inactiveTrackColor: NeonColors.pointGreen.withValues(alpha: 0.2),
              thumbColor: NeonColors.primary,
              trackHeight: 10,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: viewModel.speedLevel.toDouble(),
              min: 1.0,
              max: 5.0,
              divisions: 4,
              onChanged: (val) => viewModel.setSpeedLevel(val.toInt()),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('느릿느릿', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: NeonColors.primary.withValues(alpha: 0.6))),
              Text('보통', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: NeonColors.primary.withValues(alpha: 0.6))),
              Text('빠르게', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: NeonColors.primary.withValues(alpha: 0.6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSpecificCard(LadderGameViewModel viewModel) {
    if (widget.mode == LadderGameMode.order) return const SizedBox.shrink();

    if (widget.mode == LadderGameMode.team) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: NeonTheme.getCardDecoration(bg: const Color(0xFFF5F4EB)),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: NeonColors.pointGreen, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.people_alt_outlined, size: 22, color: NeonColors.primary),
                ),
                const SizedBox(width: 14),
                Text('팀 나누기 구성', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: NeonColors.primary)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('만들 팀 수', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: NeonColors.textMain)),
                Row(
                  children: [
                    Neon3DButton(
                      size: 40,
                      onPressed: () {
                        if (viewModel.teamCount > 2) {
                          viewModel.setTeamCount(viewModel.teamCount - 1);
                          _syncControllersWithViewModel(viewModel);
                        }
                      },
                      child: const Icon(Icons.remove, color: Colors.white, size: 18),
                    ),
                    Container(
                      width: 44,
                      alignment: Alignment.center,
                      child: Text('${viewModel.teamCount}', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: NeonColors.primary)),
                    ),
                    Neon3DButton(
                      size: 40,
                      onPressed: () {
                        if (viewModel.teamCount < viewModel.playerCount) {
                          viewModel.setTeamCount(viewModel.teamCount + 1);
                          _syncControllersWithViewModel(viewModel);
                        }
                      },
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Color(0xFFE5E0D5)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('팀장 랜덤 선정', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: NeonColors.textMain)),
                GestureDetector(
                  onTap: () => viewModel.setHasTeamLeader(!viewModel.hasTeamLeader),
                  child: Container(
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(color: const Color(0xFFE9E9E0), borderRadius: BorderRadius.circular(20)),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          left: viewModel.hasTeamLeader ? 50 : 4,
                          top: 4,
                          child: Container(
                            width: 46,
                            height: 32,
                            decoration: BoxDecoration(
                              color: NeonColors.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), offset: const Offset(0, 2), blurRadius: 3)],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              viewModel.hasTeamLeader ? 'ON' : 'OFF',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                            ),
                          ),
                        ),
                        if (!viewModel.hasTeamLeader)
                          const Positioned(right: 12, top: 0, bottom: 0, child: Center(child: Text('ON', style: TextStyle(color: NeonColors.textSub, fontSize: 11, fontWeight: FontWeight.bold)))),
                        if (viewModel.hasTeamLeader)
                          const Positioned(left: 12, top: 0, bottom: 0, child: Center(child: Text('OFF', style: TextStyle(color: NeonColors.textSub, fontSize: 11, fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: NeonTheme.getCardDecoration(bg: const Color(0xFFE9E9DE)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: NeonColors.pointOrange, borderRadius: BorderRadius.circular(12)),
                child: Icon(_getModeIcon(widget.mode), size: 22, color: NeonColors.primary),
              ),
              const SizedBox(width: 14),
              Text(_getModeSettingLabel(widget.mode), style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: NeonColors.primary)),
            ],
          ),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _itemControllers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: NeonColors.stroke, width: 2.0),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            alignment: Alignment.center,
                            child: Text('${index + 1}', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: NeonColors.primary)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _itemControllers[index],
                              decoration: InputDecoration(
                                hintText: _getHintText(widget.mode),
                                border: InputBorder.none,
                                hintStyle: GoogleFonts.plusJakartaSans(color: NeonColors.textSub.withValues(alpha: 0.5)),
                              ),
                              style: GoogleFonts.plusJakartaSans(fontSize: 15, color: NeonColors.textMain, fontWeight: FontWeight.w600),
                              onChanged: (val) {
                                viewModel.updatePenaltyContent(index, val);
                                setState(() {}); // To update start button state
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_itemControllers.length > 1) {
                        viewModel.removePenaltyItem(index);
                        setState(() => _syncControllersWithViewModel(viewModel));
                      }
                    },
                    child: const Icon(Icons.remove_circle, color: Color(0xFFBE2D06), size: 28),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              viewModel.addPenaltyItem();
              setState(() => _syncControllersWithViewModel(viewModel));
            },
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(
                painter: DashedRectPainter(radius: 16, color: NeonColors.primary.withValues(alpha: 0.3)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 20, color: NeonColors.primary),
                    const SizedBox(width: 10),
                    Text('${_getModeItemName(widget.mode)} 추가', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: NeonColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Opacity(
          opacity: 0.1,
          child: Icon(_getFooterIcon(widget.mode), size: 100, color: NeonColors.primary),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '"${_getFooterQuote(widget.mode)}"',
            textAlign: TextAlign.center,
            style: GoogleFonts.gaegu(
              fontSize: 18, 
              color: NeonColors.textSub, 
              fontStyle: FontStyle.italic, 
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ],
    );
  }

  IconData _getFooterIcon(LadderGameMode mode) {
    switch (mode) {
      case LadderGameMode.penalty: return Icons.psychology;
      case LadderGameMode.win: return Icons.celebration;
      case LadderGameMode.treat: return Icons.restaurant;
      case LadderGameMode.order: return Icons.linear_scale;
      case LadderGameMode.team: return Icons.groups;
      case LadderGameMode.manual: return Icons.auto_fix_high;
    }
  }

  String _getFooterQuote(LadderGameMode mode) {
    switch (mode) {
      case LadderGameMode.penalty: return "피할 수 없으면 즐겨라!\n피하고 싶어도 사다리는 정직합니다.";
      case LadderGameMode.win: return "우리 중 가장 운좋은 사람은\n과연 누구일까요? 행운을 빕니다!";
      case LadderGameMode.treat: return "지갑은 가볍게, 마음은 즐겁게!\n오늘의 골든벨 주인공은?";
      case LadderGameMode.order: return "운명은 정해졌습니다.\n시작은 당신의 몫입니다!";
      case LadderGameMode.team: return "최고의 전략은 최고의 팀워크에서\n나옵니다! 팀원들을 믿으세요.";
      case LadderGameMode.manual: return "당신만의 규칙으로 게임을 더 즐겁게 만드세요!";
    }
  }

  void _applyAllChanges(LadderGameViewModel viewModel) {
    for (int i = 0; i < _itemControllers.length; i++) {
      viewModel.updatePenaltyContent(i, _itemControllers[i].text);
    }
  }

  String _getModeTitle(LadderGameMode mode) {
    switch (mode) {
      case LadderGameMode.penalty: return '벌칙 설정';
      case LadderGameMode.win: return '당첨 설정';
      case LadderGameMode.treat: return '쏘기 설정';
      case LadderGameMode.order: return '순서 설정';
      case LadderGameMode.team: return '팀 나누기 설정';
      case LadderGameMode.manual: return '직접 입력 설정';
    }
  }

  IconData _getModeIcon(LadderGameMode mode) {
    switch (mode) {
      case LadderGameMode.penalty: return Icons.warning;
      case LadderGameMode.win: return Icons.grade;
      case LadderGameMode.treat: return Icons.icecream;
      case LadderGameMode.manual: return Icons.edit_note;
      default: return Icons.settings;
    }
  }

  String _getModeSettingLabel(LadderGameMode mode) {
    switch (mode) {
      case LadderGameMode.penalty: return '벌칙 설정';
      case LadderGameMode.win: return '당첨 설정';
      case LadderGameMode.treat: return '쏘기 설정';
      case LadderGameMode.manual: return '내용 입력 구성';
      default: return '설정 입력';
    }
  }

  String _getModeItemName(LadderGameMode mode) {
    switch (mode) {
      case LadderGameMode.penalty: return '벌칙';
      case LadderGameMode.win: return '당첨';
      case LadderGameMode.treat: return '쏘기';
      case LadderGameMode.manual: return '입력';
      default: return '항목';
    }
  }

  String _getHintText(LadderGameMode mode) {
    switch (mode) {
      case LadderGameMode.penalty: return '예: 커피 쏘기';
      case LadderGameMode.win: return '예: 커피 한 잔';
      case LadderGameMode.treat: return '예: 아이스크림 쏘기';
      default: return '내용을 입력하세요';
    }
  }
}

class DashedRectPainter extends CustomPainter {
  final double radius;
  final Color color;
  DashedRectPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(radius)));
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    for (final pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(pathMetric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
