import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/settings/settings_view_model.dart';

class Neon3DButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double size;
  final Color? baseColor;
  final Color? shadowColor;
  final bool isCircle;

  const Neon3DButton({
    super.key,
    required this.child,
    this.onPressed,
    this.size = 64,
    this.baseColor,
    this.shadowColor,
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

  @override
  Widget build(BuildContext context) {
    const double shadowDepth = 4.0;
    final bool isEnabled = widget.onPressed != null;
    final colors = context.watch<SettingsViewModel>().currentTheme;
    
    final Color effectiveBaseColor = widget.baseColor ?? colors.primary;
    final Color effectiveStrokeColor = colors.stroke;

    return GestureDetector(
      onPanDown: (_) {
         if (isEnabled) { setState(() => _isPressed = true); _controller.forward(); }
      },
      onPanCancel: () {
         if (isEnabled) { setState(() => _isPressed = false); _controller.reverse(); }
      },
      onTap: widget.onPressed,
      onTapDown: (_) {
         if (isEnabled) { setState(() => _isPressed = true); _controller.forward(); }
      },
      onTapUp: (_) {
         if (isEnabled) { setState(() => _isPressed = false); _controller.reverse(); }
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
                color: isEnabled ? effectiveBaseColor : const Color(0xFFDED9CD),
                shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: widget.isCircle ? null : BorderRadius.circular(24),
                border: Border.all(color: effectiveStrokeColor.withValues(alpha: isEnabled ? 1.0 : 0.4), width: 2),
                boxShadow: [
                  if (!_isPressed && isEnabled)
                    BoxShadow(
                      color: effectiveStrokeColor,
                      offset: Offset(0, currentShadowDepth),
                      blurRadius: 0,
                    ),
                ],
              ),
              child: Opacity(
                opacity: isEnabled ? 1.0 : 0.5,
                child: Center(child: widget.child)
              ),
            ),
          );
        },
      ),
    );
  }
}

class Neon3DBigButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const Neon3DBigButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
  });

  @override
  State<Neon3DBigButton> createState() => _Neon3DBigButtonState();
}

class _Neon3DBigButtonState extends State<Neon3DBigButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double shadowDepth = 8.0;
    final bool isEnabled = widget.onPressed != null;
    final colors = context.watch<SettingsViewModel>().currentTheme;
    
    final Color effectiveColor = widget.color ?? colors.primary;
    // Determine context-aware text color
    final Color textColor = (widget.color == null) 
        ? colors.onPrimary 
        : (widget.color == colors.accent ? colors.onAccent : Colors.white);

    return GestureDetector(
      onTapDown: (_) {
        if (isEnabled) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (isEnabled) setState(() => _isPressed = false);
      },
      onTapCancel: () {
        if (isEnabled) setState(() => _isPressed = false);
      },
      onTap: widget.onPressed,
      child: Transform.translate(
        offset: Offset(0, _isPressed && isEnabled ? shadowDepth : 0),
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            color: isEnabled ? effectiveColor : const Color(0xFFDED9CD),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: colors.stroke.withValues(alpha: isEnabled ? 1.0 : 0.4), width: 2),
            boxShadow: [
              if (!_isPressed && isEnabled)
                BoxShadow(
                  color: colors.stroke,
                  offset: const Offset(0, shadowDepth),
                  blurRadius: 0,
                ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              color: isEnabled ? textColor : colors.textSub.withValues(alpha: 0.6),
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
