import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays water-themed sound effects on habit interactions.
/// Respects the user's sounds_enabled setting.
class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  /// Call once at app start to pre-warm the audio engine.
  static Future<void> init() async {
    await _player.setVolume(0.8);
  }

  static Future<bool> _soundsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sounds_enabled') ?? true;
  }

  /// Single water drop — played on every habit check-off.
  static Future<void> playDrop() async {
    if (!await _soundsEnabled()) return;
    await _player.play(AssetSource('sounds/water_drop.mp3'));
  }

  /// Gentle wave splash — played when all habits are done for the day.
  static Future<void> playWave() async {
    if (!await _soundsEnabled()) return;
    await _player.play(AssetSource('sounds/wave.mp3'));
  }

  /// Flowing water — played on a stage-up celebration.
  static Future<void> playFlow() async {
    if (!await _soundsEnabled()) return;
    await _player.play(AssetSource('sounds/flow.mp3'));
  }
}
