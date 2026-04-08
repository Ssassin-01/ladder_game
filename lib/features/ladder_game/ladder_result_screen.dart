import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/neon_theme.dart';
import '../../core/widgets/neon_3d_button.dart';
import '../../core/sound_manager.dart';
import '../settings/settings_view_model.dart';
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
  late List<ResultItem> _sortedResults;
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareScreenshot() async {
    try {
      final image = await _screenshotController.capture(delay: const Duration(milliseconds: 10));
      if (image == null) return;
      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/ladder_result.png').create();
      await imagePath.writeAsBytes(image);
      await Share.shareXFiles([XFile(imagePath.path)], text: '사다리 게임 결과입니다!');
    } catch (e) {
      debugPrint("Error sharing: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<LadderGameViewModel>();
    final bool isOrderMode = viewModel.currentMode == LadderGameMode.order;
    final bool isManualMode = viewModel.currentMode == LadderGameMode.manual;
    
    _sortedResults = List.from(widget.results);
    _sortedResults.sort((a, b) {
      if (isOrderMode) {
        int aNum = int.tryParse(a.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
        int bNum = int.tryParse(b.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
        return aNum.compareTo(bNum);
      } else if (isManualMode) {
        return 0; // Don't sort for manual mode
      } else {
        final aLeader = a.text.contains('팀장');
        final bLeader = b.text.contains('팀장');
        if (aLeader && !bLeader) return -1;
        if (!aLeader && bLeader) return 1;

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

    for (int i = 0; i < _controllers.length; i++) {
        final ctrl = _controllers[i];
      Future.delayed(Duration(milliseconds: i * 120), () {
        if (mounted) {
          ctrl.forward();
          SoundManager().playPop();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }
  Widget build(BuildContext context) {
    final settingsViewModel = context.watch<SettingsViewModel>();
    final colors = settingsViewModel.currentTheme;
    final viewModel = context.watch<LadderGameViewModel>();
    final isForest = settingsViewModel.currentThemeId == LadderThemeId.forest;
    final isNeon = settingsViewModel.currentThemeId == LadderThemeId.neon;
    final isOcean = settingsViewModel.currentThemeId == LadderThemeId.ocean;

    final bool isOrderMode = viewModel.currentMode == LadderGameMode.order;
    final bool isManualMode = viewModel.currentMode == LadderGameMode.manual;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    String titleText = isManualMode ? '게임 결과' : '내기 결과';
    if (isOrderMode) {
      titleText = '최종 순위';
    } else if (viewModel.currentMode == LadderGameMode.team) {
      titleText = '팀 나누기 결과';
    }
    final bool isTeamMode = viewModel.currentMode == LadderGameMode.team;

    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: isLandscape ? 48 : 64,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: colors.primary, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            titleText,
            style: GoogleFonts.plusJakartaSans(
              color: colors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.share, color: colors.primary),
              onPressed: _shareScreenshot,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    SafeArea(
                      top: false,
                      bottom: false,
                      child: isTeamMode
                        ? _buildTeamModeLayout(viewModel, colors, isForest, isNeon, isOcean)
                        : (isOrderMode 
                          ? _buildOrderModeLayout(colors, isForest, isNeon, isOcean)
                          : (isManualMode
                             ? _buildManualModeLayout(colors, isForest, isNeon, isOcean)
                             : (isLandscape 
                                ? _buildLandscapeLayout(colors, isForest, isNeon, isOcean) 
                                : _buildPortraitLayout(colors, isForest, isNeon, isOcean)))),
                    ),
                    const SizedBox(height: 100), 
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomActions(context, colors),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, LadderThemeData colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: colors.background.withOpacity(0.85),
        border: Border(top: BorderSide(color: colors.stroke.withOpacity(0.1), width: 1.5)),
      ),
      child: Neon3DBigButton(
        label: '홈으로 돌아가기',
        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
      ),
    );
  }

  Widget _buildManualModeLayout(LadderThemeData colors, bool isForest, bool isNeon, bool isOcean) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: _sortedResults.asMap().entries.map((entry) {
          final index = entry.key;
          final result = entry.value;
          final animalColor = result.color;
          final darkerColor = Color.lerp(animalColor, Colors.black, 0.45)!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ScaleTransition(
              scale: index < _animations.length ? _animations[index] : const AlwaysStoppedAnimation(1.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: NeonTheme.getCardDecoration(
                  bg: colors.cardBg,
                  radius: 22,
                  strokeColor: colors.stroke.withOpacity(0.15),
                ).copyWith(
                  boxShadow: [
                    BoxShadow(
                      color: animalColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: darkerColor.withOpacity(0.2), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: animalColor.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(result.emoji, style: const TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.name,
                            style: GoogleFonts.plusJakartaSans(
                              color: colors.textSub,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            result.text.isEmpty ? '(입력 내용 없음)' : result.text,
                            style: GoogleFonts.plusJakartaSans(
                              color: isForest ? colors.textMain : (colors.cardBg.computeLuminance() > 0.6 ? colors.textMain : Colors.white),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.primary.withOpacity(0.2), width: 1),
                      ),
                      child: Icon(Icons.check_circle_outline, color: colors.primary, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTeamModeLayout(LadderGameViewModel viewModel, LadderThemeData colors, bool isForest, bool isNeon, bool isOcean) {
    final Map<String, List<ResultItem>> teamGroups = {};
    for (final r in widget.results) {
      String key = "기타";
      final match = RegExp(r'(\d+팀)').firstMatch(r.text);
      if (match != null) {
        key = match.group(1)!;
      } else if (r.text.contains("팀")) {
        key = r.text.split(" ")[0]; 
      }
      teamGroups.putIfAbsent(key, () => []).add(r);
    }

    final sortedKeys = teamGroups.keys.toList()
      ..sort((a, b) {
        final na = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 99;
        final nb = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 99;
        return na.compareTo(nb);
      });

    return Column(
      children: sortedKeys.asMap().entries.map((entry) {
        final teamIdx = entry.key;
        final teamKey = entry.value;
        final members = teamGroups[teamKey]!;
        
        members.sort((a, b) {
          final aLeader = a.text.contains('팀장');
          final bLeader = b.text.contains('팀장');
          if (aLeader && !bLeader) return -1;
          if (!aLeader && bLeader) return 1;
          return 0;
        });
        
        final teamNum = int.tryParse(teamKey.replaceAll(RegExp(r'[^0-9]'), '')) ?? (teamIdx + 1);
        final teamColor = LadderGameViewModel.teamColors[(teamNum - 1) % LadderGameViewModel.teamColors.length];
        final darkerTeamColor = Color.lerp(teamColor, Colors.black, 0.65)!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: ScaleTransition(
            scale: teamIdx < _animations.length ? _animations[teamIdx] : const AlwaysStoppedAnimation(1.0),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: NeonTheme.getCardDecoration(
                bg: colors.cardBg,
                strokeColor: isOcean ? colors.stroke : colors.stroke.withOpacity(0.1)
              ).copyWith(
                boxShadow: isOcean ? [
                  BoxShadow(
                    color: colors.stroke.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ] : (isForest ? null : [
                  BoxShadow(color: colors.stroke.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                ]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: teamColor.withOpacity(0.15),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: teamColor.withOpacity(0.2), shape: BoxShape.circle),
                          child: Center(child: Text('${teamIdx + 1}', style: TextStyle(color: darkerTeamColor, fontWeight: FontWeight.bold))),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          teamKey,
                          style: GoogleFonts.plusJakartaSans(
                            color: colors.textMain,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: colors.background.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
                          child: Text('${members.length}명', style: GoogleFonts.plusJakartaSans(color: colors.textSub, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: members.map((member) {
                        final isLeader = member.text.contains('팀장');
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isLeader ? teamColor.withOpacity(0.08) : colors.background.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isLeader ? teamColor : colors.stroke.withOpacity(0.1),
                              width: isLeader ? 2 : 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(member.emoji, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: colors.textMain,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (isLeader)
                                    Text(
                                      '👑 팀장',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: isLeader ? teamColor : colors.textSub,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderModeLayout(LadderThemeData colors, bool isForest, bool isNeon, bool isOcean) {
    return Column(
      children: _sortedResults.asMap().entries.map((entry) {
        final index = entry.key;
        final result = entry.value;
        final rankNum = index + 1;
        final isTop = rankNum == 1;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ScaleTransition(
            scale: index < _animations.length ? _animations[index] : const AlwaysStoppedAnimation(1.0),
            child: Container(
              height: 90,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: NeonTheme.getCardDecoration(
                bg: colors.cardBg,
                strokeColor: isTop ? colors.modeOrder : colors.stroke.withOpacity(0.1),
              ).copyWith(
                border: Border.all(
                  color: isTop ? colors.modeOrder : colors.stroke.withOpacity(0.2),
                  width: isTop ? 2.5 : 2.0,
                ),
                boxShadow: isTop ? [
                  BoxShadow(color: colors.modeOrder.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))
                ] : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    decoration: BoxDecoration(
                      color: isTop ? colors.modeOrder : colors.modeOrder.withOpacity(0.2),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                      ),
                      border: Border(right: BorderSide(color: isTop ? colors.modeOrder : colors.stroke.withOpacity(0.1), width: 2)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$rankNum',
                      style: GoogleFonts.plusJakartaSans(
                        color: isTop 
                            ? (isForest ? Colors.white : (colors.modeOrder.computeLuminance() > 0.5 ? colors.textMain : Colors.white))
                            : colors.textMain,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: colors.stroke.withOpacity(0.1), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(result.emoji, style: const TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.name,
                          style: GoogleFonts.plusJakartaSans(
                            color: colors.textSub,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.text,
                          style: GoogleFonts.plusJakartaSans(
                            color: isTop ? colors.modeOrder : colors.primary,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rankNum == 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Icon(Icons.stars, color: colors.modeWin, size: 32),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLandscapeLayout(LadderThemeData colors, bool isForest, bool isNeon, bool isOcean) {
    final viewModel = context.read<LadderGameViewModel>();
    final bool isWinMode = viewModel.currentMode == LadderGameMode.win;
    final bool isTreatMode = viewModel.currentMode == LadderGameMode.treat;
    
    final subTitle = isWinMode ? '아쉬운 분들' : (isTreatMode ? '무료 급식소' : '살아남은 인원');

    final mainResults = _sortedResults.where((r) => 
        !(r.text.contains('통과') || r.text.contains('꽝') || r.text.contains('얻어먹기'))).toList();
    final subResults = _sortedResults.where((r) => 
        (r.text.contains('통과') || r.text.contains('꽝') || r.text.contains('얻어먹기'))).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: mainResults.map((result) => _buildPenaltyCard(result, colors, isForest, isNeon, isOcean, compact: true, 
              isWinMode: isWinMode, isTreatMode: isTreatMode)).toList(),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: colors.stroke.withOpacity(0.1), width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(subTitle, 
                    style: GoogleFonts.plusJakartaSans(color: colors.textSub, fontWeight: FontWeight.w900)),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 5,
                  ),
                  itemCount: subResults.length,
                  itemBuilder: (context, index) => _buildPassItem(subResults[index], colors),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(LadderThemeData colors, bool isForest, bool isNeon, bool isOcean) {
    final viewModel = context.read<LadderGameViewModel>();
    final bool isWinMode = viewModel.currentMode == LadderGameMode.win;
    final bool isTreatMode = viewModel.currentMode == LadderGameMode.treat;

    final mainResults = _sortedResults.where((r) => 
        !(r.text.contains('통과') || r.text.contains('꽝') || r.text.contains('얻어먹기'))).toList();
    final subResults = _sortedResults.where((r) => 
        (r.text.contains('통과') || r.text.contains('꽝') || r.text.contains('얻어먹기'))).toList();

    String subTitle = '살아남은 인원';
    if (isWinMode) {
      subTitle = '아쉬운 결과';
    } else if (isTreatMode) {
      subTitle = '무료 급식 성공!';
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: mainResults.map((result) => _buildPenaltyCard(result, colors, isForest, isNeon, isOcean, isWinMode: isWinMode, isTreatMode: isTreatMode)).toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (subResults.isNotEmpty)
          Text(subTitle,
            style: GoogleFonts.plusJakartaSans(color: colors.textSub, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 12, runSpacing: 12,
            alignment: WrapAlignment.center,
            children: subResults.map((result) => _buildPassItem(result, colors)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPenaltyCard(ResultItem result, LadderThemeData colors, bool isForest, bool isNeon, bool isOcean, {bool compact = false, bool isWinMode = false, bool isTreatMode = false, bool isOrderMode = false}) {
    final i = _sortedResults.indexOf(result);
    
    Color statusBg = colors.modePenalty;
    String titleText = '벌칙 당첨';

    if (isWinMode) {
      statusBg = colors.modeWin;
      titleText = '당첨 결과';
    } else if (isTreatMode) {
      statusBg = colors.modeShoot;
      titleText = '오늘의 결제자!';
    } else if (isOrderMode) {
      statusBg = colors.modeOrder;
      titleText = '영광의 1순위';
    }
    
    final darkerModeColor = Color.lerp(statusBg, Colors.black, 0.4)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ScaleTransition(
        scale: i < _animations.length ? _animations[i] : const AlwaysStoppedAnimation(1.0),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 20 : 28),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                statusBg.withOpacity(0.05),
                statusBg.withOpacity(0.2),
              ],
            ),
            border: Border.all(
              color: statusBg.withOpacity(0.4),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isOcean ? colors.stroke.withValues(alpha: 0.2) : statusBg.withValues(alpha: 0.15),
                blurRadius: isOcean ? 20 : 15,
                spreadRadius: isOcean ? 2 : 1,
                offset: Offset(0, isOcean ? 12 : 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  titleText,
                  style: GoogleFonts.plusJakartaSans(
                    color: isForest ? darkerModeColor : (statusBg.computeLuminance() > 0.5 ? (isNeon ? colors.textMain : (isOcean ? colors.onCardBg : colors.onCardBg)) : Colors.white), 
                    fontSize: compact ? 13 : 15, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              SizedBox(height: compact ? 16 : 24),
              Container(
                width: compact ? 70 : 110, height: compact ? 70 : 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: Colors.white,
                  border: Border.all(color: statusBg.withOpacity(0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: statusBg.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(result.emoji, style: TextStyle(fontSize: compact ? 38 : 56)),
              ),
              SizedBox(height: compact ? 16 : 24),
              Text(
                result.name, 
                style: GoogleFonts.plusJakartaSans(
                  color: colors.textMain, 
                  fontSize: compact ? 18 : 22, 
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                decoration: NeonTheme.getCardDecoration(
                  bg: statusBg, 
                  radius: 20,
                  strokeColor: colors.stroke.withOpacity(0.2)
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    result.text, 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: isForest ? Colors.white : (statusBg.computeLuminance() > 0.5 ? (isOcean ? colors.onCardBg : colors.textMain) : Colors.white), 
                      fontSize: compact ? 20 : 26, 
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassItem(ResultItem result, LadderThemeData colors) {
    final i = _sortedResults.indexOf(result);

    return ScaleTransition(
      scale: i < _animations.length ? _animations[i] : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.stroke.withOpacity(0.1), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(result.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              result.name, 
              style: GoogleFonts.plusJakartaSans(
                color: colors.textSub, 
                fontSize: 14, 
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
