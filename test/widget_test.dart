import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_bird/main.dart';
import 'package:flappy_bird/services/storage_service.dart';
import 'package:flappy_bird/services/audio_service.dart';
import 'package:flappy_bird/ui/screens/home_screen.dart';
import 'package:flappy_bird/ui/screens/game_screen.dart';
import 'package:flappy_bird/ui/overlays/game_hud_overlay.dart';
import 'package:flappy_bird/game/flappy_game.dart';
import 'package:flappy_bird/models/game_state.dart';

void main() {
  testWidgets('FlappyBirdApp renders splash screen successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FlappyBirdApp());
    expect(find.text('FLAPPY '), findsOneWidget);
    expect(find.text('PENGUIN'), findsOneWidget);

    // Let the 5-second splash timer and transition complete
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('HomeScreen renders with SwiftUI style, right-facing penguin, and without app name or snowy summit text', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'flappy_high_score': 85,
      'flappy_coins': 120,
    });
    final storage = await StorageService.init();
    final audio = AudioService(storage);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          storage: storage,
          audio: audio,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Check that App Name and Snowy Summit text are strictly absent
    expect(find.text('FLAPPY PENGUIN'), findsNothing);
    expect(find.text('SNOWY SUMMITS'), findsNothing);

    // 2. Check that Best Distance and Coins are rendered
    expect(find.text('BEST DISTANCE'), findsOneWidget);
    expect(find.text('85m'), findsOneWidget);
    expect(find.text('COINS'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);

    // 3. Check that the Play Game button is present
    expect(find.text('PLAY GAME'), findsOneWidget);

    // 4. Verify horizontal flip is applied to make penguin face right
    final transformFinder = find.byWidgetPredicate(
      (widget) => widget is Transform && widget.transform.storage[0] == -1.0,
    );
    expect(transformFinder, findsAtLeastNWidgets(1));

    // 5. Verify Scenery button is present
    expect(find.text('CHANGE SCENERY'), findsOneWidget);
  });

  testWidgets('HomeScreen opens Scenery modal, selects Mountain, and saves', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'flappy_scenery': 'ice',
      'flappy_unlocked_mountain': true,
    });
    final storage = await StorageService.init();
    final audio = AudioService(storage);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          storage: storage,
          audio: audio,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Change Scenery button
    await tester.tap(find.text('CHANGE SCENERY'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify modal options are visible
    expect(find.text('SELECT SCENERY'), findsOneWidget);
    expect(find.text('ICE SUMMIT'), findsOneWidget);
    expect(find.text('MOUNTAIN'), findsOneWidget);
    expect(find.text('DESERT'), findsOneWidget);
    expect(find.text('Classic Pipes'), findsOneWidget);
    expect(find.text('Cactus'), findsOneWidget);

    // Tap Mountain card
    await tester.tap(find.text('MOUNTAIN'));
    await tester.pump(const Duration(milliseconds: 200));

    // Tap SAVE button
    await tester.tap(find.text('SAVE'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify scenery was saved to storage
    expect(storage.scenery, equals('mountain'));
    expect(find.text('CHANGE SCENERY'), findsOneWidget);
  });

  testWidgets('HomeScreen opens Scenery modal, selects Desert with Cactus, and saves', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'flappy_scenery': 'ice',
      'flappy_unlocked_desert': true,
    });
    final storage = await StorageService.init();
    final audio = AudioService(storage);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          storage: storage,
          audio: audio,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Change Scenery button
    await tester.tap(find.text('CHANGE SCENERY'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify DESERT and Cactus options
    expect(find.text('DESERT'), findsOneWidget);
    expect(find.text('CACTUS'), findsOneWidget);

    // Tap Desert card
    await tester.tap(find.text('DESERT'));
    await tester.pump(const Duration(milliseconds: 200));

    // Tap SAVE button
    await tester.tap(find.text('SAVE'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify scenery was saved to storage
    expect(storage.scenery, equals('desert'));
  });

  testWidgets('HomeScreen scenery modal displays Mountain locked for 800 coins and Desert for 1000 coins when player has insufficient coins', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'flappy_scenery': 'ice',
      'flappy_coins': 250,
    });
    final storage = await StorageService.init();
    final audio = AudioService(storage);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          storage: storage,
          audio: audio,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Open scenery modal
    await tester.tap(find.text('CHANGE SCENERY'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify lock price indicators on Mountain (800) and Desert (1000)
    expect(find.text('800'), findsOneWidget);
    expect(find.text('1000'), findsOneWidget);

    // Select Mountain
    await tester.tap(find.text('MOUNTAIN'));
    await tester.pump(const Duration(milliseconds: 200));

    // Because player has 250 coins (< 800), both preview banner and action button show locked indicator
    expect(find.text('LOCKED • 800 COINS'), findsNWidgets(2));

    // Select Desert
    await tester.tap(find.text('DESERT'));
    await tester.pump(const Duration(milliseconds: 200));

    // Because player has 250 coins (< 1000), both preview banner and action button show locked indicator
    expect(find.text('LOCKED • 1000 COINS'), findsNWidgets(2));
  });

  testWidgets('HomeScreen scenery modal allows unlocking Mountain for 800 coins and deducts coins from total', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'flappy_scenery': 'ice',
      'flappy_coins': 950,
    });
    final storage = await StorageService.init();
    final audio = AudioService(storage);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          storage: storage,
          audio: audio,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Open scenery modal
    await tester.tap(find.text('CHANGE SCENERY'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Select Mountain
    await tester.tap(find.text('MOUNTAIN'));
    await tester.pump(const Duration(milliseconds: 200));

    // Button should offer UNLOCK FOR 800 COINS since player has 950 coins
    final unlockButton = find.text('UNLOCK FOR 800 COINS');
    expect(unlockButton, findsOneWidget);

    // Tap unlock button
    await tester.tap(unlockButton);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify mountain is now unlocked and selected
    expect(storage.scenery, equals('mountain'));
    expect(storage.isSceneryUnlocked('mountain'), isTrue);
    // Verify 800 coins were deducted: 950 - 800 = 150
    expect(storage.coins, equals(150));
    expect(find.text('150'), findsOneWidget); // Displayed on home screen coin pill
  });

  testWidgets('Tapping PLAY GAME navigates to GameScreen and initializes FlappyGame without error', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'flappy_scenery': 'ice',
    });
    final storage = await StorageService.init();
    final audio = AudioService(storage);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          storage: storage,
          audio: audio,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Tap PLAY GAME button
    await tester.tap(find.text('PLAY GAME'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify GameScreen is displayed without any LateInitializationError
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('GameHudOverlay renders live meter and updates in real time', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final audio = AudioService(storage);
    final game = FlappyGame(storage: storage, audio: audio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameHudOverlay(game: game),
        ),
      ),
    );
    await tester.pump();

    // 1. In ready state: Verify live meter pill ('0' and 'm') and tap prompt are visible
    expect(find.text('0'), findsOneWidget);
    expect(find.text('m'), findsOneWidget);
    expect(find.byIcon(Icons.near_me_rounded), findsOneWidget);
    expect(find.text('TAP ANYWHERE TO FLY'), findsOneWidget);

    // 2. Start playing: status changes to playing and score updates
    game.statusNotifier.value = GameStatus.playing;
    game.scoreNotifier.value = 145;
    await tester.pump();

    // Center prompt should disappear, but live meter MUST remain clearly visible!
    expect(find.text('TAP ANYWHERE TO FLY'), findsNothing);
    expect(find.text('145'), findsOneWidget);
    expect(find.text('m'), findsOneWidget);
    expect(find.byIcon(Icons.near_me_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
  });
}
