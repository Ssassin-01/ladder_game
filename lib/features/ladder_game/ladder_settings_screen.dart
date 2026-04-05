import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/neon_theme.dart';
import '../../core/widgets/neon_3d_button.dart';
import 'ladder_game_mode.dart';
import 'ladder_game_view_model.dart';
import 'ladder_game_screen.dart';

class LadderSettingsScreen extends StatefulWidget {
  final LadderGameMode mode;

  const LadderSettingsScreen({super.key, required this.mode});

  @override
  State<LadderSettingsScreen> createState() => _LadderSettingsScreenState();
}

class _LadderSettingsScreenState extends State<LadderSettingsScreen> {
  final List<TextEditingController> _itemControllers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<LadderGameViewModel>();
      _syncControllersWithViewModel(viewModel);
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
  }

  @override
  void dispose() {
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LadderGameViewModel>();
    final String title = _getModeTitle(widget.mode);

    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: _buildAppBar(context, title, viewModel),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Use a container for the overall 3-card grouping as seen in Stitch redesign
              Column(
                children: [
                  // 1. Participant Count Card
                  _buildParticipantCard(viewModel),
                  const SizedBox(height: 20),

                  // 2. Ladder Speed Card
                  _buildSpeedCard(viewModel),
                  const SizedBox(height: 20),

                  // 3. Mode Specific Content (The 3rd card in the sequence)
                  _buildModeSpecificCard(viewModel),
                  const SizedBox(height: 32),

                  // 4. Start Button (Big 3D Action)
                  Neon3DBigButton(
                    label: '게임 시작',
                    onPressed: () {
                      _applyAllChanges(viewModel);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LadderGameScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // 5. Decorative Footer
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
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: NeonColors.primary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: NeonColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            viewModel.resetSettings();
            setState(() => _syncControllersWithViewModel(viewModel));
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
                  // Existing Participant management logic
                },
                child: const Icon(Icons.inventory, size: 18, color: NeonColors.shadow),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Neon3DButton(
                size: 64,
                onPressed: () {
                  if (viewModel.playerCount > 2) {
                    viewModel.setPlayerCount(viewModel.playerCount - 1);
                    _syncControllersWithViewModel(viewModel);
                  }
                },
                child: const Icon(Icons.remove, color: Colors.white, size: 32),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  '${viewModel.playerCount}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: NeonColors.primary,
                  ),
                ),
              ),
              Neon3DButton(
                size: 64,
                onPressed: () {
                  if (viewModel.playerCount < 20) {
                    viewModel.setPlayerCount(viewModel.playerCount + 1);
                    _syncControllersWithViewModel(viewModel);
                  }
                },
                child: const Icon(Icons.add, color: Colors.white, size: 32),
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
      return Column(
        children: [
           Container(
            padding: const EdgeInsets.all(28),
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
                    Text('팀 수', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: NeonColors.primary)),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Neon3DButton(
                      size: 56,
                      onPressed: () {
                        if (viewModel.teamCount > 2) {
                           viewModel.setTeamCount(viewModel.teamCount - 1);
                           _syncControllersWithViewModel(viewModel);
                        }
                      },
                      child: const Icon(Icons.remove, color: Colors.white, size: 24),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text('${viewModel.teamCount}', style: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.w900, color: NeonColors.primary)),
                    ),
                    Neon3DButton(
                      size: 56,
                      onPressed: () {
                        if (viewModel.teamCount < viewModel.playerCount) {
                          viewModel.setTeamCount(viewModel.teamCount + 1);
                          _syncControllersWithViewModel(viewModel);
                        }
                      },
                      child: const Icon(Icons.add, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: NeonTheme.getCardDecoration(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('팀장 선정', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: NeonColors.primary)),
                GestureDetector(
                  onTap: () => viewModel.setHasTeamLeader(!viewModel.hasTeamLeader),
                  child: Container(
                    width: 110,
                    height: 44,
                    decoration: BoxDecoration(color: const Color(0xFFE9E9E0), borderRadius: BorderRadius.circular(22)),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          left: viewModel.hasTeamLeader ? 58 : 4,
                          top: 4,
                          child: Container(
                            width: 48,
                            height: 36,
                            decoration: BoxDecoration(
                              color: NeonColors.primary,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), offset: const Offset(0, 2), blurRadius: 4)],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              viewModel.hasTeamLeader ? '예' : '아니오',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                        ),
                        if (!viewModel.hasTeamLeader)
                          const Positioned(right: 14, top: 0, bottom: 0, child: Center(child: Text('예', style: TextStyle(color: NeonColors.textSub, fontSize: 12, fontWeight: FontWeight.bold)))),
                        if (viewModel.hasTeamLeader)
                          const Positioned(left: 14, top: 0, bottom: 0, child: Center(child: Text('아니오', style: TextStyle(color: NeonColors.textSub, fontSize: 12, fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                        border: Border.all(color: Colors.transparent, width: 2),
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
                              onChanged: (val) => viewModel.updatePenaltyContent(index, val),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_itemControllers.length > 2) {
                        viewModel.setPenaltyCount(viewModel.penaltyCount - 1);
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
              viewModel.setPenaltyCount(viewModel.penaltyCount + 1);
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
        const Opacity(
          opacity: 0.2,
          child: Icon(Icons.auto_awesome, size: 100, color: NeonColors.primary),
        ),
        const SizedBox(height: 16),
        Text(
          '"정상은 멋지지만, 올라가는 과정이 진짜 재미있죠!"',
          textAlign: TextAlign.center,
          style: GoogleFonts.gaegu(fontSize: 17, color: NeonColors.textSub, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
        ),
      ],
    );
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
      case LadderGameMode.manual: return '입력 구성';
      default: return '설정';
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
