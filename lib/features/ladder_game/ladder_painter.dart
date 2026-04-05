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
  final LadderGameViewModel? viewModel;
  final double ladderHeight;

  LadderPainter({
    required this.playerCount,
    required this.sectionCount,
    required this.ladderBars,
    this.activePathIndices,
    this.participantColors,
    required this.animationMap,
    this.viewModel,
    required this.ladderHeight,
  }) : super(repaint: Listenable.merge(animationMap.values.toList()));

  @override
  void paint(Canvas canvas, Size size) {
    final sectionWidth = size.width / (playerCount + 1);
    final sectionHeight = ladderHeight / (sectionCount + 1);

    void drawLadderLine(Offset p1, Offset p2, Color color, {double width = 2.0}) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(p1, p2, paint);
    }

    // 기본 사다리 선 색상 (숲 테마의 브라운)
    final baseLineColor = NeonColors.primary.withOpacity(0.2);
    
    // 수직선 그리기
    for (int i = 0; i < playerCount; i++) {
      final x = sectionWidth * (i + 1);
      drawLadderLine(Offset(x, 0), Offset(x, ladderHeight), baseLineColor, width: 2.0);
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
          drawLadderLine(Offset(x1, y1), Offset(x2, y2), baseLineColor, width: 2.0);
        }
      }
    }

    // 활성화된 애니메이션 경로 그리기
    if (activePathIndices != null && participantColors != null && viewModel != null) {
      for (final index in activePathIndices!) {
        final anim = animationMap[index];
        if (anim == null) continue;
        
        final offsets = viewModel!.getPath(index, Size(size.width, ladderHeight));
        if (offsets.isEmpty) continue;

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
        final corePaint = Paint()
          ..color = color
          ..strokeWidth = 5.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        final shadowPaint = Paint()
          ..color = color.withOpacity(0.2)
          ..strokeWidth = 8.0
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
          ..strokeCap = StrokeCap.round;

        for (final metric in pathMetrics) {
          final remaining = currentLength - drawLength;
          if (remaining <= 0) break;
          final segmentToDraw = remaining.clamp(0.0, metric.length);
          final extractPath = metric.extractPath(0, segmentToDraw);
          
          canvas.drawPath(extractPath, shadowPaint);
          canvas.drawPath(extractPath, corePaint);
          
          drawLength += metric.length;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant LadderPainter oldDelegate) => true;
}
