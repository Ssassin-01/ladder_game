import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'neon_theme.dart';

class NeonButton extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const NeonButton({
    super.key,
    required this.text,
    this.color = NeonColors.cyan, // 기본값은 사이언
    required this.onPressed,
    this.width = 200,
    this.height = 60,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // 터치 시 버튼이 잠깐 커졌다 작아지는 애니메이션 (타격감 강조)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    // 1. 애니메이션 실행 (스케일업)
    await _controller.forward();
    // 2. 다시 돌아오기 (스케일다운)
    await _controller.reverse();
    // 3. 실제 동작 실행
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: isDarkMode ? NeonColors.backgroundBlack : const Color(0xFF1A237E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? widget.color : Colors.white.withOpacity(0.3),
              width: 3, 
            ),
            boxShadow: isDarkMode ? [
              BoxShadow(
                color: widget.color.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: isDarkMode ? NeonColors.getGlow(widget.color) : null,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ),
    );
  }
}
