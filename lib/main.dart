import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/home/ladder_home_screen.dart';
import 'features/ladder_game/ladder_game_view_model.dart';
import 'features/settings/settings_view_model.dart';
import 'core/sound_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 설정 모델 초기화
  final settingsVM = SettingsViewModel();
  await settingsVM.init();
  
  await SoundManager().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsVM),
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
    return Consumer<SettingsViewModel>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: '사다리 게임 마스터',
          debugShowCheckedModeBanner: false,
          theme: settings.themeData,
          home: const LadderHomeScreen(),
        );
      },
    );
  }
}
