import 'package:audioplayers/audioplayers.dart';

/// Tiny fire-and-forget sound helper for UI feedback (follow, reactions).
///
/// Uses one low-latency player and never throws into the UI — if audio fails
/// (silent mode, missing codec, etc.) the interaction still works.
class SoundPlayer {
  SoundPlayer._() {
    // audioplayers' AssetSource prepends AudioCache.instance.prefix (default
    // "assets/"). This project's asset root is "Assets/" (capital A) with no
    // lowercase "assets/" folder, so clear the global prefix and pass the full
    // path ourselves.
    AudioCache.instance.prefix = '';
    _player.setReleaseMode(ReleaseMode.stop);
  }
  static final SoundPlayer instance = SoundPlayer._();

  final AudioPlayer _player = AudioPlayer(playerId: 'ui_sfx');

  // Full asset paths exactly as declared in pubspec (prefix cleared above).
  static const _followPath = 'Assets/sound/Followsound.mp3';
  static const _reactionPath = 'Assets/sound/reaction.mp3';

  Future<void> _play(String path) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(path));
    } catch (_) {
      // Ignore — sound is a nicety, not a requirement.
    }
  }

  /// Played when the user follows / unfollows someone.
  void follow() => _play(_followPath);

  /// Played when the user reacts to a post.
  void reaction() => _play(_reactionPath);
}
