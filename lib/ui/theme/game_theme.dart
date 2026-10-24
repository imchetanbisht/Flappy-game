import 'package:flutter/material.dart';

class GameTheme {
  // Brand colors
  static const Color primary = Color(0xFFFF9F1C);
  static const Color primaryDark = Color(0xFFE07A5F);
  static const Color accent = Color(0xFF2EC4B6);
  static const Color gold = Color(0xFFFFD166);
  static const Color purple = Color(0xFF7209B7);
  static const Color crimson = Color(0xFFE63946);
  static const Color darkBg = Color(0xFF14141E);
  static const Color surfaceDark = Color(0xDD1E1E2C);
  static const Color cardBg = Color(0xEE27293D);

  // Text Styles
  static TextStyle arcadeTitle({double fontSize = 34, Color color = Colors.white}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 2.0,
      color: color,
      shadows: const [
        Shadow(color: Colors.black54, offset: Offset(2, 3), blurRadius: 4),
        Shadow(color: Color(0x66FF9F1C), offset: Offset(0, 0), blurRadius: 12),
      ],
    );
  }

  static TextStyle arcadeSubtitle({double fontSize = 18, Color color = Colors.white70}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      color: color,
      shadows: const [
        Shadow(color: Colors.black87, offset: Offset(1, 2), blurRadius: 3),
      ],
    );
  }

  static TextStyle numberBadge({double fontSize = 28, Color color = gold}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.0,
      color: color,
      shadows: const [
        Shadow(color: Colors.black87, offset: Offset(2, 2), blurRadius: 4),
      ],
    );
  }

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFFFF8F00)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient buttonGreenGradient = LinearGradient(
    colors: [Color(0xFF48CAE4), Color(0xFF0096C7), Color(0xFF023E8A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient buttonOrangeGradient = LinearGradient(
    colors: [Color(0xFFFFB703), Color(0xFFFB8500), Color(0xFFE85D04)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient buttonPurpleGradient = LinearGradient(
    colors: [Color(0xFFD63384), Color(0xFF9D4EDD), Color(0xFF5A189A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static BoxDecoration glassCardDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: borderColor ?? Colors.white.withAlpha(40),
        width: 1.5,
      ),
      boxShadow: const [
        BoxShadow(
          color: Colors.black54,
          offset: Offset(0, 10),
          blurRadius: 20,
        ),
      ],
    );
  }
}
