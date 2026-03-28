import 'dart:ui';
import 'package:flutter/material.dart';
import 'ladder_game_view_model.dart';
import '../../core/neon_theme.dart';

class LadderPainter extends CustomPainter {
  final int playerCount;
  final int sectionCount;
  final List<List<LadderBar>> ladderBars;
  final Map<int, List<Offset>>? activePaths;
  final List<Color>? participantColors;
  final Animation<double> animation;
  final bool isDarkMode; // 추가

  LadderPainter({
    required this.playerCount,
    required this.sectionCount,
    required this.ladderBars,
    this.activePaths,
    this.participantColors,
    required this.animation,
    this.isDarkMode = true, // 기본값 설정
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final sectionWidth = size.width / (playerCount + 1);
    final sectionHeight = size.height / (sectionCount + 2);

    void drawNeonLine(
      Offset p1,
      Offset p2,
      Color color, {
      double width = 3.0,
    }) {
      if (isDarkMode) {
        final glowPaint1 =
            Paint()
              ..color = color.withOpacity(0.15)
              ..strokeWidth = width * 4.0
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
              ..strokeCap = StrokeCap.round;

        final corePaint =
            Paint()
              ..color = color
              ..strokeWidth = width
              ..strokeCap = StrokeCap.round;

        canvas.drawLine(p1, p2, glowPaint1);
        canvas.drawLine(p1, p2, corePaint);
      } else {
        // 라이트 모드: 빛 번짐 없이 선명한 선 (약간 어둡게 처리)
        final corePaint =
            Paint()
              ..color = color.withOpacity(0.8)
              ..strokeWidth = width * 1.2
              ..strokeCap = StrokeCap.round;
        canvas.drawLine(p1, p2, corePaint);
      }
    }

    // 1. 기본 배경 사다리
    final baseColor = isDarkMode ? NeonColors.cyan.withOpacity(0.35) : NeonColors.solidCyan.withOpacity(0.4);
    for (int i = 0; i < playerCount; i++) {
      final x = sectionWidth * (i + 1);
      drawNeonLine(
        Offset(x, sectionHeight * 0.5),
        Offset(x, sectionHeight * (sectionCount + 1.5)),
        baseColor,
        width: 1.2,
      );
    }

    for (int i = 0; i < playerCount - 1; i++) {
      final x1 = sectionWidth * (i + 1);
      final x2 = sectionWidth * (i + 2);
      for (int j = 0; j < sectionCount; j++) {
        final bar = ladderBars[i][j];
        if (bar.exists) {
          final y1 = sectionHeight * (j + 1.5) + (bar.startYOffset * sectionHeight);
          final y2 = sectionHeight * (j + 1.5) + (bar.endYOffset * sectionHeight);
          drawNeonLine(Offset(x1, y1), Offset(x2, y2), baseColor, width: 1.2);
        }
      }
    }

    // 2. 활성화된 경로 애니메이션
    if (activePaths != null && participantColors != null) {
      activePaths!.forEach((index, offsets) {
        if (offsets.isEmpty) return;
        final color = participantColors![index];

        final path = Path();
        path.moveTo(offsets.first.dx, offsets.first.dy);
        for (var i = 1; i < offsets.length; i++) {
          path.lineTo(offsets[i].dx, offsets[i].dy);
        }

        final pathMetrics = path.computeMetrics().toList();
        final totalLength = pathMetrics.fold(0.0, (prev, m) => prev + m.length);
        final currentLength = totalLength * animation.value;

        double drawLength = 0;
        for (final metric in pathMetrics) {
          final remaining = currentLength - drawLength;
          if (remaining <= 0) break;

          final segmentToDraw = remaining.clamp(0.0, metric.length);
          final extractPath = metric.extractPath(0, segmentToDraw);

          if (isDarkMode) {
            final glowPaint = Paint()
              ..color = color.withOpacity(0.4)
              ..strokeWidth = 10.0
              ..style = PaintingStyle.stroke
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0)
              ..strokeCap = StrokeCap.round;

            final corePaint = Paint()
              ..color = color
              ..strokeWidth = 4.5
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round;

            canvas.drawPath(extractPath, glowPaint);
            canvas.drawPath(extractPath, corePaint);
          } else {
            // 라이트 모드: 선명한 선
            final corePaint = Paint()
              ..color = color
              ..strokeWidth = 5.0
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round;
            canvas.drawPath(extractPath, corePaint);
          }

          drawLength += metric.length;
        }
      });
    }
  }

  @override
  bool shouldRepaint(covariant LadderPainter oldDelegate) => true;
}
