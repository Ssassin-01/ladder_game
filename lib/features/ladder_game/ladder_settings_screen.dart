import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/neon_theme.dart';
import '../../core/neon_button.dart';
import 'ladder_game_screen.dart';
import 'ladder_game_view_model.dart';

class LadderSettingsScreen extends StatefulWidget {
  const LadderSettingsScreen({super.key});

  @override
  State<LadderSettingsScreen> createState() => _LadderSettingsScreenState();
}

class _LadderSettingsScreenState extends State<LadderSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final viewModel = context.watch<LadderGameViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: themeProvider.isDarkMode ? NeonColors.cyan : NeonColors.solidCyan),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '사다리 설정',
          style: TextStyle(
            color: themeProvider.isDarkMode ? NeonColors.cyan : NeonColors.solidCyan,
            shadows: NeonColors.getGlow(NeonColors.cyan, isDarkMode: themeProvider.isDarkMode),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode, color: themeProvider.isDarkMode ? NeonColors.cyan : NeonColors.solidCyan),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. 참가자 수 설정
              _sectionTitle('참가자 수', themeProvider.isDarkMode ? NeonColors.electricYellow : NeonColors.solidYellow, themeProvider.isDarkMode),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _circleButton('-', () {
                    if (viewModel.playerCount > 2) viewModel.setPlayerCount(viewModel.playerCount - 1);
                  }, themeProvider.isDarkMode),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Text(
                      '${viewModel.playerCount}명',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _circleButton('+', () {
                    if (viewModel.playerCount < 8) viewModel.setPlayerCount(viewModel.playerCount + 1);
                  }, themeProvider.isDarkMode),
                ],
              ),
              const SizedBox(height: 40),

              // 2. 사다리 속도 설정 (Slider UI)
              _sectionTitle('사다리 속도 (${viewModel.speedLevel}단계)', themeProvider.isDarkMode ? NeonColors.limeGreen : NeonColors.solidGreen, themeProvider.isDarkMode),
              const SizedBox(height: 10),
              Slider(
                value: viewModel.speedLevel.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: themeProvider.isDarkMode ? NeonColors.limeGreen : NeonColors.solidGreen,
                onChanged: (val) => viewModel.setSpeedLevel(val.toInt()),
              ),
              const SizedBox(height: 40),

              // 3. 가림막 사용 유무
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _sectionTitle('가림막 사용', themeProvider.isDarkMode ? NeonColors.cyan : NeonColors.solidCyan, themeProvider.isDarkMode),
                  const SizedBox(width: 15),
                  Switch(
                    value: viewModel.isShroudVisible,
                    onChanged: (val) => viewModel.toggleShroudSetting(),
                    activeColor: NeonColors.hotPink,
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // 4. 시작하기 버튼
              NeonButton(
                text: '게임 시작!',
                color: themeProvider.isDarkMode ? NeonColors.limeGreen : NeonColors.solidGreen,
                width: 200,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LadderGameScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        shadows: NeonColors.getGlow(color, isDarkMode: isDarkMode),
      ),
    );
  }

  Widget _circleButton(String text, VoidCallback onPressed, bool isDarkMode) {
    final color = isDarkMode ? NeonColors.cyan : NeonColors.solidCyan;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 45, height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
