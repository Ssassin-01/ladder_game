import 'package:flutter/material.dart';
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
    this.color = NeonColors.cyberCyan, // 기본값은 사이버 시안
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
    // 터치 시 스케일이 약간 커졌다 작아지는 애니메이션 (타격감 강조)
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
    // 1. 애니메이션 실행 (스케일 업)
    await _controller.forward();
    // 2. 다시 돌아오기 (스케일 다운)
    await _controller.reverse();
    // 3. 실제 동작 수행
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: NeonColors.backgroundBlack, // 배경은 블랙
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.color,
              width: 3, // 두꺼운 네온 테두리
            ),
            boxShadow: [
              // 테두리에 네온 발광 효과 (BoxShadow)
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              // 텍스트에 네온 발광 효과 (Shadow)
              shadows: NeonColors.getGlow(widget.color),
              fontFamily: 'Roboto', // 실제 고딕 계열 폰트가 앱에 설정되어야 함
            ),
          ),
        ),
      ),
    );
  }
}
