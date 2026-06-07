import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays water-themed sounds on habit interactions.
/// All methods are silently no-op on web, and respect the user's toggle.
class SoundService {
  static bool _enabled = true;
  static AudioPlayer? _player;

  static Future<void> init() async {
    if (kIsWeb) return;
    _player = AudioPlayer();
    // Restore saved preference so the toggle survives app restarts.
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('sounds_enabled') ?? true;
  }

  /// Called by Settings whenever the toggle changes.
  static void setEnabled(bool value) => _enabled = value;

  static Future<void> playDrop() => _play('assets/sounds/water_drop_new.mp3');
  static Future<void> playWave() => _play('assets/sounds/wave.wav');
  static Future<void> playFlow() => _play('assets/sounds/flow.wav');

  static Future<void> _play(String asset) async {
    if (kIsWeb || !_enabled) return;
    try {
      final p = _player ?? AudioPlayer();
      await p.setAsset(asset);
      await p.seek(Duration.zero);
      await p.play();
    } catch (_) {
      // Silently ignore — never crash on a sound error.
    }
  }
}
