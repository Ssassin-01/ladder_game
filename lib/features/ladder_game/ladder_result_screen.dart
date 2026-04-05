import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/neon_theme.dart';
import '../../core/sound_manager.dart';
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
    
    _sortedResults = List.from(widget.results);
    _sortedResults.sort((a, b) {
      if (isOrderMode) {
        int aNum = int.tryParse(a.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
        int bNum = int.tryParse(b.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
        return aNum.compareTo(bNum);
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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LadderGameViewModel>();
    final bool isOrderMode = viewModel.currentMode == LadderGameMode.order;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    String titleText = '내기 결과';
    if (isOrderMode) {
      titleText = '최종 순위';
    } else if (viewModel.currentMode == LadderGameMode.team) {
      titleText = '팀 나누기 결과';
    }
    final bool isTeamMode = viewModel.currentMode == LadderGameMode.team;

    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: NeonColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: isLandscape ? 48 : 64,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: NeonColors.primary, size: isLandscape ? 20 : 22),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            titleText,
            style: GoogleFonts.plusJakartaSans(
              color: NeonColors.primary,
              fontSize: isLandscape ? 18 : 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: NeonColors.primary),
              onPressed: _shareScreenshot,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: isTeamMode
            ? _buildTeamModeLayout(viewModel)
            : (isOrderMode 
              ? _buildOrderModeLayout()
              : (isLandscape 
                  ? _buildLandscapeLayout() 
                  : _buildPortraitLayout())),
        ),
      ),
    );
  }

  Widget _buildTeamModeLayout(LadderGameViewModel viewModel) {
    final Map<String, List<ResultItem>> teamGroups = {};
    for (final r in widget.results) {
      final match = RegExp(r'^(\d+)팀').firstMatch(r.text);
      final key = match != null ? '${match.group(1)}팀' : r.text;
      teamGroups.putIfAbsent(key, () => []).add(r);
    }

    final sortedKeys = teamGroups.keys.toList()
      ..sort((a, b) {
        final na = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final nb = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return na.compareTo(nb);
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: sortedKeys.length,
      itemBuilder: (_, teamIdx) {
        final teamKey = sortedKeys[teamIdx];
        final members = teamGroups[teamKey]!;
        members.sort((a, b) {
          final aIsLeader = a.text.contains('팀장');
          final bIsLeader = b.text.contains('팀장');
          if (aIsLeader && !bIsLeader) return -1;
          if (!aIsLeader && bIsLeader) return 1;
          return 0;
        });
        
        final teamNum = int.tryParse(teamKey.replaceAll(RegExp(r'[^0-9]'), '')) ?? (teamIdx + 1);
        final teamColor = LadderGameViewModel.teamColors[(teamNum - 1) % LadderGameViewModel.teamColors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ScaleTransition(
            scale: teamIdx < _animations.length ? _animations[teamIdx] : const AlwaysStoppedAnimation(1.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: NeonColors.stroke.withOpacity(0.1), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: NeonColors.shadow.withOpacity(0.08),
                    offset: const Offset(0, 8),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: teamColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          teamKey,
                          style: TextStyle(
                            color: teamColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${members.length}명',
                          style: TextStyle(color: teamColor.withOpacity(0.6), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: members.map((member) {
                        final isLeader = member.text.contains('팀장');
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isLeader ? teamColor.withOpacity(0.05) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isLeader ? teamColor : NeonColors.textSub.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(member.emoji, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: const TextStyle(
                                      color: NeonColors.textMain,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (isLeader)
                                    Text(
                                      '팀장',
                                      style: TextStyle(
                                        color: teamColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
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
      },
    );
  }

  Widget _buildOrderModeLayout() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _sortedResults.length,
      itemBuilder: (context, index) {
        final result = _sortedResults[index];
        final rankNum = index + 1;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ScaleTransition(
            scale: _animations[index],
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: NeonColors.stroke.withOpacity(0.1), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: NeonColors.shadow.withOpacity(0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    decoration: BoxDecoration(
                      color: NeonColors.primary.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$rankNum',
                      style: const TextStyle(
                        color: NeonColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF9F7F2),
                      border: Border.all(color: NeonColors.primary.withOpacity(0.1), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(result.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.name,
                          style: const TextStyle(
                            color: NeonColors.textSub,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                          Text(
                            result.text,
                            style: const TextStyle(
                              color: NeonColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (rankNum == 1)
                    const Padding(
                      padding: EdgeInsets.only(right: 20),
                      child: Icon(Icons.stars, color: Colors.amber, size: 28),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLandscapeLayout() {
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
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: mainResults.map((result) => _buildPenaltyCard(result, compact: true, 
                isWinMode: isWinMode, isTreatMode: isTreatMode)).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFFE5E0D5))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(subTitle, 
                    style: const TextStyle(color: NeonColors.textSub, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: subResults.length,
                    itemBuilder: (context, index) => _buildPassItem(subResults[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout() {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          ...mainResults.map((result) => _buildPenaltyCard(result, isWinMode: isWinMode, isTreatMode: isTreatMode)),
          const SizedBox(height: 10),
          if (subResults.isNotEmpty)
            Text(subTitle,
              style: const TextStyle(color: NeonColors.textSub, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12, runSpacing: 12,
            alignment: WrapAlignment.center,
            children: subResults.map((result) => _buildPassItem(result, width: (MediaQuery.of(context).size.width - 60) / 3))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPenaltyCard(ResultItem result, {bool compact = false, bool isWinMode = false, bool isTreatMode = false, bool isOrderMode = false}) {
    final i = _sortedResults.indexOf(result);
    
    Color statusColor = const Color(0xFFBE2D06);
    String titleText = '벌칙 당첨';

    if (isWinMode) {
      statusColor = Colors.amber;
      titleText = '당첨 결과';
    } else if (isTreatMode) {
      statusColor = Colors.orange;
      titleText = '오늘의 결제자!';
    } else if (isOrderMode) {
      statusColor = NeonColors.primary;
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: NeonColors.stroke.withOpacity(0.1), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: NeonColors.shadow.withOpacity(0.1),
                offset: const Offset(0, 8),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(titleText,
                style: TextStyle(color: statusColor, fontSize: compact ? 15 : 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              SizedBox(height: compact ? 12 : 24),
              Container(
                width: compact ? 70 : 110, height: compact ? 70 : 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: const Color(0xFFF9F7F2),
                  border: Border.all(color: NeonColors.primary.withOpacity(0.1), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(result.emoji, style: TextStyle(fontSize: compact ? 40 : 60)),
              ),
              SizedBox(height: compact ? 12 : 24),
              Text(result.name, style: const TextStyle(color: NeonColors.textMain, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(16)
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    result.text, 
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusColor, 
                      fontSize: compact ? 22 : 26, 
                      fontWeight: FontWeight.bold,
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

  Widget _buildPassItem(ResultItem result, {double? width, bool isFullWidth = false}) {
    final i = _sortedResults.indexOf(result);
    final viewModel = context.read<LadderGameViewModel>();
    final bool isOrderMode = viewModel.currentMode == LadderGameMode.order;

    return ScaleTransition(
      scale: _animations[i],
      child: Container(
        width: width ?? (isFullWidth ? double.infinity : null),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NeonColors.primary.withOpacity(0.1), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(result.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.name, style: const TextStyle(color: NeonColors.textSub, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  Text(result.text, style: TextStyle(color: isOrderMode ? NeonColors.primary : NeonColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
