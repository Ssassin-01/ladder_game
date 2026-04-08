import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/neon_theme.dart';

class SettingsViewModel extends ChangeNotifier {
  static const String _keyTheme = 'ladder_theme_id';
  static const String _keySound = 'ladder_sound_enabled';
  static const String _keyHaptic = 'ladder_haptic_enabled';

  LadderThemeId _currentThemeId = LadderThemeId.forest;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;

  LadderThemeId get currentThemeId => _currentThemeId;
  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;

  LadderThemeData get currentTheme => NeonColors.getTheme(_currentThemeId);
  ThemeData get themeData => NeonTheme.getThemeData(_currentThemeId);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 로드 테마
    final themeIndex = prefs.getInt(_keyTheme);
    if (themeIndex != null && themeIndex < LadderThemeId.values.length) {
      _currentThemeId = LadderThemeId.values[themeIndex];
    }

    // 로드 소리/진동
    _soundEnabled = prefs.getBool(_keySound) ?? true;
    _hapticEnabled = prefs.getBool(_keyHaptic) ?? true;
    
    notifyListeners();
  }

  Future<void> setTheme(LadderThemeId themeId) async {
    if (_currentThemeId == themeId) return;
    _currentThemeId = themeId;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTheme, themeId.index);
    
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySound, _soundEnabled);
    notifyListeners();
  }

  Future<void> toggleHaptic() async {
    _hapticEnabled = !_hapticEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHaptic, _hapticEnabled);
    notifyListeners();
  }
}
