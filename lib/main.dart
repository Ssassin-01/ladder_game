import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/neon_theme.dart';
import 'features/home/home_screen.dart';
import 'features/ladder_game/ladder_game_view_model.dart';

void main() {
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
      title: '친구랑 내기 한판 ㄱ?',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      home: const HomeScreen(),
    );
  }
}
