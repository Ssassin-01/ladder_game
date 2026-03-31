import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/neon_theme.dart';
import 'features/home/ladder_home_screen.dart';
import 'features/ladder_game/ladder_game_view_model.dart';

import 'core/sound_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoundManager().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LadderGameViewModel()),
      ],
      child: const LadderGameApp(),
    ),
  );
}

class LadderGameApp extends StatelessWidget {
  const LadderGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: '사다리 게임 마스터',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      home: const LadderHomeScreen(),
    );
  }
}
