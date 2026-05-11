import 'package:audioplayers/audioplayers.dart';

class SoundPlayer {
  final AudioPlayer _player = AudioPlayer();

  // Future<void> playSound() async {
  //   await _player.play(AssetSource('icon/multi-pop-5-188168.mp3'));
  // }

  Future<void> playsendreceivesound() async {
    await _player.play(AssetSource('icon/send_receive_message.mp3'));
  }

  Future<void> playlikeSound() async {
    await _player.play(AssetSource('icon/LikeSound.wav'));
  }

  Future<void> FollowSound() async {
    await _player.play(AssetSource('icon/Followsound.mp3'));
  }

  Future<void> stopSound() async {
    await _player.stop();
  }

  // Future<void> feedSound()async{
  //   await _player.play(AssetSource('icon/zapsplat_multimedia_ui_refresh_load_new_content_rattle_91307.mp3'));
  // }

  Future<void> notificationsound() async {
    await _player.play(AssetSource('icon/notification_sound.mp3'));
  }
}
