import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Plays water-themed sounds on habit interactions.
/// All methods are silently no-op on web (just_audio web requires
/// a CORS-friendly server which won't work in local PWA mode).
class SoundService {
  static bool _enabled = true;
  static AudioPlayer? _player;

  static Future<void> init() async {
    if (kIsWeb) return;
    _player = AudioPlayer();
  }

  /// Called by settings to enable/disable sounds.
  static void setEnabled(bool value) => _enabled = value;

  static Future<void> playDrop() => _play('assets/sounds/water_drop.wav');
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
      // Silently ignore playback errors so the app never crashes on sound issues.
    }
  }
}
