import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? NeonColors.backgroundBlack
                      : const Color(0xFFF8F9FA),
              gradient:
                  isDarkMode
                      ? const RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.5,
                        colors: [Color(0xFF000814), NeonColors.backgroundBlack],
                      )
                      : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFFFFF), Color(0xFFF0F2F5)],
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
                          Text(
                            '사다리 게임',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color:
                                  isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF1A237E),
                              letterSpacing: -1.5,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            '마스터',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color:
                                  isDarkMode
                                      ? NeonColors.cyan
                                      : const Color(0xFF1A237E),
                              letterSpacing: -1.0,
                              height: 1.1,
                              shadows:
                                  isDarkMode
                                      ? NeonColors.getGlow(NeonColors.cyan)
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? NeonColors.hotPink
                                      : const Color(0xFF1A237E),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow:
                                  isDarkMode
                                      ? NeonColors.getGlow(NeonColors.hotPink)
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '오늘의 운명은 누구에게?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                              letterSpacing: 2.0,
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
                                  LadderGameMode.order,
                                  NeonColors.limeGreen,
                                  delay: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildModeButton(
                            context,
                            LadderGameMode.manual,
                            Colors.white,
                            isFullWidth: true,
                            delay: 0.6,
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
          // 우측 상단 테마 토글 버튼
          Positioned(
            top: 10,
            right: 16,
            child: SafeArea(
              child: FadeTransition(
                opacity: _controller,
                child: _buildIconCircle(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  () => themeProvider.toggleTheme(),
                  isDarkMode,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconCircle(IconData icon, VoidCallback onTap, bool isDarkMode) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkMode ? const Color(0xFF121212) : Colors.white,
          border: Border.all(
            color: isDarkMode ? Colors.white12 : Colors.black12,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDarkMode ? Colors.white70 : Colors.black87,
          size: 24,
        ),
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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

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
            color:
                isDarkMode ? const Color(0xFF111111) : const Color(0xFF1A237E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  isDarkMode
                      ? widget.accentColor.withOpacity(0.4)
                      : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              if (isDarkMode)
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: -2,
                )
              else
                BoxShadow(
                  color: const Color(0xFF1A237E).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Stack(
            children: [
              if (isDarkMode)
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
