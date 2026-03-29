import 'dart:ui';
import 'package:flutter/material.dart';
import 'ladder_game_view_model.dart';
import '../../core/neon_theme.dart';

class LadderPainter extends CustomPainter {
  final int playerCount;
  final int sectionCount;
  final List<List<LadderBar>> ladderBars;
  final Set<int>? activePathIndices;
  final Map<int, Animation<double>> animationMap;
  final List<Color>? participantColors;
  final bool isDarkMode;
  final LadderGameViewModel? viewModel;
  final double ladderHeight; // 외부에서 계산된 정확한 사다리 영역 높이

  LadderPainter({
    required this.playerCount,
    required this.sectionCount,
    required this.ladderBars,
    this.activePathIndices,
    this.participantColors,
    required this.animationMap,
    this.isDarkMode = true,
    this.viewModel,
    required this.ladderHeight,
  }) : super(repaint: Listenable.merge(animationMap.values.toList()));

  @override
  void paint(Canvas canvas, Size size) {
    final sectionWidth = size.width / (playerCount + 1);
    final sectionHeight = ladderHeight / (sectionCount + 1);

    void drawNeonLine(Offset p1, Offset p2, Color color, {double width = 3.0}) {
      if (isDarkMode) {
        final glowPaint1 = Paint()
          ..color = color.withOpacity(0.15)
          ..strokeWidth = width * 4.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
          ..strokeCap = StrokeCap.round;
        final corePaint = Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(p1, p2, glowPaint1);
        canvas.drawLine(p1, p2, corePaint);
      } else {
        final hsvColor = HSVColor.fromColor(color);
        final darkenedColor = hsvColor
            .withValue((hsvColor.value * 0.7).clamp(0.0, 1.0))
            .withSaturation((hsvColor.saturation * 1.2).clamp(0.0, 1.0))
            .toColor();
        final corePaint = Paint()
          ..color = darkenedColor.withOpacity(0.9)
          ..strokeWidth = width * 1.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(p1, p2, corePaint);
      }
    }

    final baseColor = isDarkMode
        ? NeonColors.cyan.withOpacity(0.35)
        : NeonColors.solidCyan.withOpacity(0.4);
    
    // 수직선 그리기 (사다리 영역까지만)
    for (int i = 0; i < playerCount; i++) {
      final x = sectionWidth * (i + 1);
      drawNeonLine(Offset(x, 0), Offset(x, ladderHeight), baseColor, width: 1.2);
    }

    // 가로선 그리기
    for (int i = 0; i < playerCount - 1; i++) {
      final x1 = sectionWidth * (i + 1);
      final x2 = sectionWidth * (i + 2);
      for (int j = 0; j < sectionCount; j++) {
        final bar = ladderBars[i][j];
        if (bar.exists) {
          final yBase = sectionHeight * (j + 1);
          final y1 = yBase + (bar.startYOffset * sectionHeight);
          final y2 = yBase + (bar.endYOffset * sectionHeight);
          drawNeonLine(Offset(x1, y1), Offset(x2, y2), baseColor, width: 1.2);
        }
      }
    }

    if (activePathIndices != null && participantColors != null && viewModel != null) {
      for (final index in activePathIndices!) {
        final anim = animationMap[index];
        if (anim == null) continue;
        
        final offsets = viewModel!.getPath(index, Size(size.width, ladderHeight));
        if (offsets.isEmpty) continue;

        final lastX = offsets.last.dx;
        offsets.add(Offset(lastX, size.height)); 

        final color = participantColors![index];
        final path = Path();
        path.moveTo(offsets.first.dx, offsets.first.dy);
        for (var i = 1; i < offsets.length; i++) {
          path.lineTo(offsets[i].dx, offsets[i].dy);
        }
        final pathMetrics = path.computeMetrics().toList();
        final totalLength = pathMetrics.fold(0.0, (prev, m) => prev + m.length);
        if (totalLength <= 0) continue;
        final currentLength = totalLength * anim.value.clamp(0.0, 1.0);
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
            final hsvColor = HSVColor.fromColor(color);
            // 라이트 모드: 선명도를 위해 더 어둡고 채도가 높은 색상 사용
            final vibrantColor = hsvColor
                .withValue((hsvColor.value * 0.5).clamp(0.0, 1.0))
                .withSaturation((hsvColor.saturation * 1.5).clamp(0.0, 1.0))
                .toColor();
            final corePaint = Paint()
              ..color = vibrantColor
              ..strokeWidth = 6.0
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round;
            canvas.drawPath(extractPath, corePaint);
          }
          drawLength += metric.length;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant LadderPainter oldDelegate) => true;
}
