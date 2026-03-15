// lib/services/audio_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';

final audioServiceProvider = Provider<AudioService>((ref) => AudioService());

class AudioService {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgPlayer = AudioPlayer();
  bool _soundEnabled = true;
  bool _musicEnabled = true;

  void setSoundEnabled(bool val) => _soundEnabled = val;
  void setMusicEnabled(bool val) {
    _musicEnabled = val;
    if (!val) {
      _bgPlayer.stop();
    } else {
      _playBgMusic();
    }
  }

  Future<void> playDiceRoll() => _playSfx(AppConstants.diceSound);
  Future<void> playTokenMove() => _playSfx(AppConstants.tokenMoveSound);
  Future<void> playTokenCut() => _playSfx(AppConstants.tokenCutSound);
  Future<void> playWin() => _playSfx(AppConstants.winSound);

  Future<void> _playSfx(String file) async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/$file'));
    } catch (_) {
      // Audio files may not be present in dev; ignore silently
    }
  }

  Future<void> _playBgMusic() async {
    if (!_musicEnabled) return;
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.play(AssetSource('audio/${AppConstants.bgMusicPath}'));
    } catch (_) {}
  }

  Future<void> startBgMusic() => _playBgMusic();
  Future<void> stopBgMusic() => _bgPlayer.stop();

  void dispose() {
    _sfxPlayer.dispose();
    _bgPlayer.dispose();
  }
}
