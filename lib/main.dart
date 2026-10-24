import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme/game_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation for standard arcade experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set edge-to-edge transparent system bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FlappyBirdApp());
}

class FlappyBirdApp extends StatelessWidget {
  const FlappyBirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flappy Penguin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: GameTheme.darkBg,
        colorScheme: const ColorScheme.dark(
          primary: GameTheme.primary,
          secondary: GameTheme.accent,
          surface: GameTheme.cardBg,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
