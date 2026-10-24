import 'package:flutter/material.dart';

class GlowingBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color backgroundColor;
  final double fontSize;

  const GlowingBadge({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor = const Color(0xFFFFD166),
    this.backgroundColor = const Color(0x991E1E2C),
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withAlpha(80), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: iconColor.withAlpha(40),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: fontSize + 4),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
              letterSpacing: 0.5,
              shadows: const [
                Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
