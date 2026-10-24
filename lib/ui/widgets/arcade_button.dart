import 'package:flutter/material.dart';

class ArcadeButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final Gradient gradient;
  final Color shadowColor;
  final double width;
  final double height;
  final double fontSize;

  const ArcadeButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.gradient = const LinearGradient(
      colors: [Color(0xFFFFB703), Color(0xFFFB8500), Color(0xFFE85D04)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    this.shadowColor = const Color(0xFFB54502),
    this.width = 220,
    this.height = 54,
    this.fontSize = 18,
  });

  @override
  State<ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double depth = 5.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.width,
        height: widget.height,
        margin: EdgeInsets.only(
          top: _isPressed ? depth : 0,
          bottom: _isPressed ? 0 : depth,
        ),
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(80), width: 1.5),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: widget.shadowColor,
                offset: const Offset(0, depth),
                blurRadius: 0,
              ),
            BoxShadow(
              color: Colors.black.withAlpha(60),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: widget.fontSize + 4),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  shadows: const [
                    Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2),
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
