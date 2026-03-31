import 'package:flutter/material.dart';

import '../../core/neon_theme.dart';
import '../ladder_game/ladder_game_mode.dart';
import '../ladder_game/ladder_settings_screen.dart';

/// 사다리 게임 마스터의 메인 홈 화면.
/// 5가지 주요 게임 모드(벌칙, 당첨, 쏘기, 순서, 직접 입력)를 선택할 수 있는 진입점입니다.
class LadderHomeScreen extends StatefulWidget {
  const LadderHomeScreen({super.key});

  @override
  State<LadderHomeScreen> createState() => _LadderHomeScreenState();
}

class _LadderHomeScreenState extends State<LadderHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 전체적인 화면 등장 애니메이션을 위한 컨트롤러
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: NeonColors.backgroundBlack,
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [Color(0xFF000814), NeonColors.backgroundBlack],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // 상단 타이틀 섹션 (여백의 미와 세련된 폰트 스타일)
                    FadeTransition(
                      opacity: _controller,
                      child: Column(
                        children: [
                          const Text(
                            '사다리 게임',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.5,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            '내기 한 판 ㄱ?',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: NeonColors.cyan,
                              letterSpacing: -1.0,
                              height: 1.1,
                              shadows: NeonColors.getGlow(NeonColors.cyan),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: NeonColors.hotPink,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: NeonColors.getGlow(NeonColors.hotPink),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    // 모드 선택 버튼 그리드
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildModeButton(
                                  context,
                                  LadderGameMode.penalty,
                                  NeonColors.hotPink,
                                  delay: 0.2,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildModeButton(
                                  context,
                                  LadderGameMode.win,
                                  NeonColors.electricYellow,
                                  delay: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildModeButton(
                                  context,
                                  LadderGameMode.treat,
                                  NeonColors.cyan,
                                  delay: 0.4,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildModeButton(
                                  context,
                                  LadderGameMode.team,
                                  NeonColors.limeGreen, // or any color you'd like
                                  delay: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildModeButton(
                                  context,
                                  LadderGameMode.order,
                                  NeonColors.electricYellow, // reused color
                                  delay: 0.6,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildModeButton(
                                  context,
                                  LadderGameMode.manual,
                                  Colors.white,
                                  delay: 0.7,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    LadderGameMode mode,
    Color accentColor, {
    bool isFullWidth = false,
    required double delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (delay * 1000).toInt()),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: _ModeButtonContent(
        mode: mode,
        accentColor: accentColor,
        isFullWidth: isFullWidth,
      ),
    );
  }
}

class _ModeButtonContent extends StatefulWidget {
  final LadderGameMode mode;
  final Color accentColor;
  final bool isFullWidth;

  const _ModeButtonContent({
    required this.mode,
    required this.accentColor,
    required this.isFullWidth,
  });

  @override
  State<_ModeButtonContent> createState() => _ModeButtonContentState();
}

class _ModeButtonContentState extends State<_ModeButtonContent> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    LadderSettingsScreen(mode: widget.mode),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: widget.isFullWidth ? 70 : 130,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.accentColor.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: -2,
                )
            ],
          ),
          child: Stack(
            children: [
                Positioned(
                  right: -10,
                  top: -10,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Center(
                child:
                    widget.isFullWidth
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.mode.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.mode.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.mode.icon,
                              style: const TextStyle(fontSize: 36),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.mode.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
