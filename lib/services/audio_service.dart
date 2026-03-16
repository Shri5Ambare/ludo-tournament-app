// lib/services/audio_service.dart
//
// Sound effects + background music for the Ludo app.
// All audio files go in assets/audio/ — see SETUP.md for the full list.
// Errors are silently swallowed so the app works fine without assets.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';

final audioServiceProvider = Provider<AudioService>((ref) => AudioService());

class AudioService {
  // Dedicated players so SFX never interrupts BG music
  final AudioPlayer _sfx1 = AudioPlayer();   // primary SFX
  final AudioPlayer _sfx2 = AudioPlayer();   // secondary (overlapping cuts etc.)
  final AudioPlayer _bgPlayer = AudioPlayer();

  bool _soundEnabled = true;
  bool _musicEnabled = true;

  // ── Settings toggles ─────────────────────────────────────────────────────

  void setSoundEnabled(bool val) => _soundEnabled = val;

  void setMusicEnabled(bool val) {
    _musicEnabled = val;
    if (!val) {
      _bgPlayer.stop();
    } else {
      startBgMusic();
    }
  }

  // ── SFX triggers ─────────────────────────────────────────────────────────

  Future<void> playDiceRoll()  => _playSfx(AppConstants.diceSound, primary: true);
  Future<void> playTokenMove() => _playSfx(AppConstants.tokenMoveSound, primary: true);
  Future<void> playTokenCut()  => _playSfx(AppConstants.tokenCutSound, primary: false);
  Future<void> playTokenHome() => _playSfx('token_home.mp3', primary: false);
  Future<void> playWin()       => _playSfx(AppConstants.winSound, primary: false);
  Future<void> playLose()      => _playSfx('game_lose.mp3', primary: false);
  Future<void> playButtonTap() => _playSfx('button_tap.mp3', primary: true);

  Future<void> _playSfx(String file, {bool primary = true}) async {
    if (!_soundEnabled) return;
    try {
      final player = primary ? _sfx1 : _sfx2;
      await player.stop();
      await player.play(AssetSource('audio/$file'));
    } catch (_) {
      // Audio files may not be present in dev — ignore silently
    }
  }

  // ── Background music ──────────────────────────────────────────────────────

  Future<void> startBgMusic() async {
    if (!_musicEnabled) return;
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(0.35); // quieter so SFX stand out
      await _bgPlayer.play(AssetSource('audio/${AppConstants.bgMusicPath}'));
    } catch (_) {}
  }

  Future<void> stopBgMusic() => _bgPlayer.stop();

  Future<void> pauseBgMusic() => _bgPlayer.pause();

  Future<void> resumeBgMusic() async {
    if (!_musicEnabled) return;
    try { await _bgPlayer.resume(); } catch (_) {}
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  void dispose() {
    _sfx1.dispose();
    _sfx2.dispose();
    _bgPlayer.dispose();
  }
}
