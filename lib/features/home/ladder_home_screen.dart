import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/neon_theme.dart';
import '../ladder_game/ladder_game_mode.dart';
import '../ladder_game/ladder_settings_screen.dart';

import '../../features/settings/settings_screen.dart';
import '../../features/settings/settings_view_model.dart';
import 'package:provider/provider.dart';

class LadderHomeScreen extends StatefulWidget {
  const LadderHomeScreen({super.key});

  @override
  State<LadderHomeScreen> createState() => _LadderHomeScreenState();
}

class _LadderHomeScreenState extends State<LadderHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final colors = settings.currentTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // 1. Top Logo Chip & Settings Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.cardBg,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: colors.primary.withValues(alpha: 0.1), blurRadius: 4, spreadRadius: 1),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.terrain, size: 18, color: colors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Ladder Master',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: colors.textMain,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    ),
                    icon: Icon(Icons.settings_rounded, color: colors.textSub),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // 2. Hero Title
              Column(
                children: [
                  Text(
                    '사다리 게임',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: colors.textMain,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    '내기 한 판?',
                    style: GoogleFonts.gaegu(
                      fontSize: 20,
                      color: colors.textSub,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 3. Mode Buttons - Asymmetrical Grid
              _buildLargeModeButton(
                context,
                LadderGameMode.penalty,
                '벌칙',
                Icons.dangerous,
                colors.modePenalty,
                colors,
                settings,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildGridModeButton(
                      context,
                      LadderGameMode.win,
                      '당첨',
                      Icons.star,
                      colors.modeWin,
                      colors,
                      settings,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildGridModeButton(
                      context,
                      LadderGameMode.treat,
                      '쏘기',
                      Icons.icecream,
                      colors.modeShoot,
                      colors,
                      settings,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildGridModeButton(
                      context,
                      LadderGameMode.order,
                      '순서',
                      Icons.format_list_numbered,
                      colors.modeOrder,
                      colors,
                      settings,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildGridModeButton(
                      context,
                      LadderGameMode.team,
                      '팀 나누기',
                      Icons.groups,
                      colors.modeTeam,
                      colors,
                      settings,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildDashedButton(
                context,
                LadderGameMode.manual,
                '직접 입력',
                Icons.edit,
                colors,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeModeButton(BuildContext context, LadderGameMode mode, String label, IconData icon, Color bgColor, LadderThemeData colors, SettingsViewModel settings) {
    // context-aware text/icon color
    final bool isForest = settings.currentThemeId == LadderThemeId.forest;
    final Color contentColor = isForest 
        ? (bgColor.computeLuminance() > 0.6 ? colors.onCardBg : Colors.white)
        : (bgColor.computeLuminance() > 0.5 ? Color(0xFF0F0F1A) : Colors.white);

    return GestureDetector(
      onTap: () => _navigateToSettings(context, mode),
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: colors.stroke, width: 2),
          boxShadow: [
            BoxShadow(
              color: colors.stroke.withValues(alpha: 0.1),
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, size: 20, color: contentColor.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: contentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(width: 60, height: 4, decoration: BoxDecoration(color: contentColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
                ],
              ),
            ),
            Positioned(
              right: 32,
              top: 20, bottom: 20,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Center(
                  child: Icon(icon, size: 48, color: contentColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridModeButton(BuildContext context, LadderGameMode mode, String label, IconData icon, Color bgColor, LadderThemeData colors, SettingsViewModel settings) {
    // context-aware text/icon color
    final bool isForest = settings.currentThemeId == LadderThemeId.forest;
    final Color contentColor = isForest 
        ? (bgColor.computeLuminance() > 0.6 ? colors.onCardBg : Colors.white)
        : (bgColor.computeLuminance() > 0.5 ? Color(0xFF0F0F1A) : Colors.white);

    return GestureDetector(
      onTap: () => _navigateToSettings(context, mode),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: colors.stroke, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: contentColor.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Icon(icon, size: 40, color: contentColor),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashedButton(BuildContext context, LadderGameMode mode, String label, IconData icon, LadderThemeData colors) {
    return GestureDetector(
      onTap: () => _navigateToSettings(context, mode),
      child: Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(35),
        ),
        child: CustomPaint(
          painter: _DashedRectPainter(color: colors.stroke, radius: 35),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: colors.stroke),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textMain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSettings(BuildContext context, LadderGameMode mode) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => LadderSettingsScreen(mode: mode),
        transitionsBuilder: (context, anim1, anim2, child) => FadeTransition(opacity: anim1, child: child),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(radius)));

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    
    for (final pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
