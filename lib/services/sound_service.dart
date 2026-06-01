import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final _player = AudioPlayer();

  static Future<void> init() async {
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  static Future<bool> _soundsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sounds_enabled') ?? true;
  }

  static Future<void> _play(String asset) async {
    try {
      if (!await _soundsEnabled()) return;
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {
      // never crash the app over a sound
    }
  }

  /// Water drop — played on each habit check-off
  static Future<void> playDrop() => _play('sounds/water_drop.wav');

  /// Wave wash — played when all habits for the day are done
  static Future<void> playWave() => _play('sounds/wave.wav');

  /// Ascending arpeggio — played on water stage progression
  static Future<void> playFlow() => _play('sounds/flow.wav');
}
