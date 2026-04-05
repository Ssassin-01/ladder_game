import 'package:flutter/material.dart';
import '../../core/neon_theme.dart';

class Neon3DButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double size;
  final Color baseColor;
  final Color shadowColor;
  final bool isCircle;

  const Neon3DButton({
    super.key,
    required this.child,
    this.onPressed,
    this.size = 64,
    this.baseColor = NeonColors.primary,
    this.shadowColor = NeonColors.shadow,
    this.isCircle = true,
  });

  @override
  State<Neon3DButton> createState() => _Neon3DButtonState();
}

class _Neon3DButtonState extends State<Neon3DButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPressedDown(PointerDownEvent details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onPressedUp(PointerUpEvent details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    const double shadowDepth = 4.0;
    
    return GestureDetector(
      onPanDown: (_) {
         if (widget.onPressed != null) { setState(() => _isPressed = true); _controller.forward(); }
      },
      onPanCancel: () {
         if (widget.onPressed != null) { setState(() => _isPressed = false); _controller.reverse(); }
      },
      onTap: widget.onPressed,
      onTapDown: (_) {
         if (widget.onPressed != null) { setState(() => _isPressed = true); _controller.forward(); }
      },
      onTapUp: (_) {
         if (widget.onPressed != null) { setState(() => _isPressed = false); _controller.reverse(); }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double currentTranslateY = _isPressed ? shadowDepth : 0.0;
          final double currentShadowDepth = _isPressed ? 0.0 : shadowDepth;
          
          return Container(
            width: widget.size,
            height: widget.size,
            padding: EdgeInsets.only(top: currentTranslateY),
            child: Container(
              decoration: BoxDecoration(
                color: widget.onPressed != null ? widget.baseColor : Colors.grey[400],
                shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: widget.isCircle ? null : BorderRadius.circular(24),
                border: Border.all(color: NeonColors.stroke, width: 2),
                boxShadow: [
                  if (!_isPressed)
                    BoxShadow(
                      color: NeonColors.stroke,
                      offset: Offset(0, currentShadowDepth),
                      blurRadius: 0,
                    ),
                ],
              ),
              child: Center(child: widget.child),
            ),
          );
        },
      ),
    );
  }
}

class Neon3DBigButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const Neon3DBigButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  State<Neon3DBigButton> createState() => _Neon3DBigButtonState();
}

class _Neon3DBigButtonState extends State<Neon3DBigButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double shadowDepth = 8.0;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: Transform.translate(
        offset: Offset(0, _isPressed ? shadowDepth : 0),
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            color: NeonColors.primary,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: NeonColors.stroke, width: 2),
            boxShadow: [
              if (!_isPressed)
                const BoxShadow(
                  color: NeonColors.stroke,
                  offset: Offset(0, shadowDepth),
                  blurRadius: 0,
                ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
