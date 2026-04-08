import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/neon_theme.dart';
import 'settings_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final colors = settings.currentTheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '환경 설정',
          style: GoogleFonts.plusJakartaSans(
            color: colors.textMain,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, '테마 선택', colors),
              const SizedBox(height: 16),
              _buildThemeGrid(context, settings),
              const SizedBox(height: 32),
              _buildSectionTitle(context, '알림 및 효과', colors),
              const SizedBox(height: 16),
              _buildSettingTile(
                context,
                title: '효과음 재생',
                subtitle: '터치 및 게임 진행 사운드',
                value: settings.soundEnabled,
                onChanged: (_) => settings.toggleSound(),
                colors: colors,
              ),
              const SizedBox(height: 12),
              _buildSettingTile(
                context,
                title: '햅틱 진동',
                subtitle: '사다리 꺾임 시 진동 피드백',
                value: settings.hapticEnabled,
                onChanged: (_) => settings.toggleHaptic(),
                colors: colors,
              ),
              const SizedBox(height: 40),
              _buildAppInfo(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, LadderThemeData colors) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        color: colors.primary,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildThemeGrid(BuildContext context, SettingsViewModel settings) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: LadderThemeId.values.length,
      itemBuilder: (context, index) {
        final themeId = LadderThemeId.values[index];
        final themeData = NeonColors.getTheme(themeId);
        final isSelected = settings.currentThemeId == themeId;

        return GestureDetector(
          onTap: () => settings.setTheme(themeId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: themeData.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? settings.currentTheme.primary : themeData.stroke.withOpacity(0.1),
                width: isSelected ? 3.0 : 1.5,
              ),
              boxShadow: isSelected ? [
                BoxShadow(color: settings.currentTheme.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
              ] : null,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeData.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: themeData.stroke.withOpacity(0.1), width: 1),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 20, height: 4, decoration: BoxDecoration(color: themeData.primary, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 4),
                              Container(width: 8, height: 4, decoration: BoxDecoration(color: themeData.accent, borderRadius: BorderRadius.circular(2))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: themeData.primary.withOpacity(0.1), shape: BoxShape.circle),
                            child: Icon(Icons.palette, color: themeData.primary, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  themeId.label,
                  style: GoogleFonts.plusJakartaSans(
                    color: isSelected ? settings.currentTheme.primary : themeData.textMain,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required LadderThemeData colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeonTheme.getCardDecoration(
        bg: Colors.white,
        radius: 24,
        strokeColor: colors.stroke.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: colors.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: colors.textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colors.primary,
            activeTrackColor: colors.accent.withOpacity(0.5),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[200],
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo(LadderThemeData colors) {
    return Center(
      child: Column(
        children: [
          Text(
            '사다리 게임 마스터',
            style: GoogleFonts.plusJakartaSans(
              color: colors.textSub.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Version 1.0.0',
            style: GoogleFonts.plusJakartaSans(
              color: colors.textSub.withOpacity(0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
