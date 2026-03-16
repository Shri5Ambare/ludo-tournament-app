// lib/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/board_themes.dart';

// ─────────────────────────────────────────────
// Settings Model
// ─────────────────────────────────────────────

class AppSettings {
  final bool soundEnabled;
  final bool musicEnabled;
  final bool vibrationEnabled;
  final String boardTheme;
  final int turnTimerSeconds;

  const AppSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
    this.boardTheme = BoardThemes.classic,
    this.turnTimerSeconds = AppConstants.defaultTurnSeconds,
  });

  AppSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? vibrationEnabled,
    String? boardTheme,
    int? turnTimerSeconds,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      boardTheme: boardTheme ?? this.boardTheme,
      turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
    );
  }
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      soundEnabled:
          prefs.getBool(AppConstants.soundEnabledKey) ?? true,
      musicEnabled:
          prefs.getBool(AppConstants.musicEnabledKey) ?? true,
      vibrationEnabled:
          prefs.getBool(AppConstants.vibrationEnabledKey) ?? true,
      boardTheme:
          prefs.getString(AppConstants.boardThemeKey) ?? BoardThemes.classic,
      turnTimerSeconds: prefs.getInt('turnTimerSeconds') ??
          AppConstants.defaultTurnSeconds,
    );
  }

  Future<void> toggleSound() async {
    state = state.copyWith(soundEnabled: !state.soundEnabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.soundEnabledKey, state.soundEnabled);
  }

  Future<void> toggleMusic() async {
    state = state.copyWith(musicEnabled: !state.musicEnabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.musicEnabledKey, state.musicEnabled);
  }

  Future<void> toggleVibration() async {
    state = state.copyWith(vibrationEnabled: !state.vibrationEnabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.vibrationEnabledKey, state.vibrationEnabled);
  }

  Future<void> setBoardTheme(String theme) async {
    state = state.copyWith(boardTheme: theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.boardThemeKey, theme);
  }

  Future<void> setTurnTimer(int seconds) async {
    state = state.copyWith(turnTimerSeconds: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('turnTimerSeconds', seconds);
  }
}
