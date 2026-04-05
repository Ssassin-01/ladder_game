import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/neon_theme.dart';
import '../ladder_game/ladder_game_mode.dart';
import '../ladder_game/ladder_settings_screen.dart';

class LadderHomeScreen extends StatefulWidget {
  const LadderHomeScreen({super.key});

  @override
  State<LadderHomeScreen> createState() => _LadderHomeScreenState();
}

class _LadderHomeScreenState extends State<LadderHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // 1. Top Logo Chip
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: NeonColors.stroke.withValues(alpha: 0.1), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.terrain, size: 18, color: NeonColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Ladder Master',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: NeonColors.textMain,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
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
                      color: NeonColors.textMain,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    '내기 한 판?',
                    style: GoogleFonts.gaegu(
                      fontSize: 20,
                      color: NeonColors.textSub,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 3. Mode Buttons - Asymmetrical Grid
              // A. Penalty (Hero Button)
              _buildLargeModeButton(
                context,
                LadderGameMode.penalty,
                '벌칙',
                Icons.dangerous,
                NeonColors.modePenalty,
              ),
              const SizedBox(height: 20),

              // B. 2x2 Grid for Other Modes
              Row(
                children: [
                  Expanded(
                    child: _buildGridModeButton(
                      context,
                      LadderGameMode.win,
                      '당첨',
                      Icons.star,
                      NeonColors.modeWin,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildGridModeButton(
                      context,
                      LadderGameMode.treat,
                      '쏘기',
                      Icons.icecream,
                      NeonColors.modeShoot,
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
                      NeonColors.modeOrder,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildGridModeButton(
                      context,
                      LadderGameMode.team,
                      '팀 나누기',
                      Icons.groups,
                      NeonColors.modeTeam,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // C. Manual Input (Dashed Footer Button)
              _buildDashedButton(
                context,
                LadderGameMode.manual,
                '직접 입력',
                Icons.edit,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeModeButton(BuildContext context, LadderGameMode mode, String label, IconData icon, Color bgColor) {
    return GestureDetector(
      onTap: () => _navigateToSettings(context, mode),
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: NeonColors.stroke, width: 2),
          boxShadow: NeonColors.get3DShadow(NeonColors.stroke.withValues(alpha: 0.1)),
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
                      Icon(Icons.warning, size: 20, color: NeonColors.stroke.withOpacity(0.5)),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: NeonColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(width: 60, height: 4, decoration: BoxDecoration(color: NeonColors.stroke.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
                ],
              ),
            ),
            Positioned(
              right: 32,
              top: 20, bottom: 20,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2, style: BorderStyle.solid),
                ),
                child: Center(
                  child: Icon(icon, size: 48, color: NeonColors.stroke),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridModeButton(BuildContext context, LadderGameMode mode, String label, IconData icon, Color bgColor) {
    return GestureDetector(
      onTap: () => _navigateToSettings(context, mode),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: NeonColors.stroke, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: NeonColors.stroke, width: 1.5),
              ),
              child: Icon(icon, size: 40, color: NeonColors.stroke),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: NeonColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashedButton(BuildContext context, LadderGameMode mode, String label, IconData icon) {
    return GestureDetector(
      onTap: () => _navigateToSettings(context, mode),
      child: Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: NeonColors.stroke, width: 2, style: BorderStyle.none),
        ),
        child: CustomPaint(
          painter: _DashedRectPainter(color: NeonColors.stroke, radius: 35),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: NeonColors.stroke),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NeonColors.textMain,
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
