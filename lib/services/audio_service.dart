import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final _playbackCompleteController = StreamController<void>.broadcast();

  Stream<void> get onPlaybackComplete => _playbackCompleteController.stream;

  AudioService() {
    _player.onPlayerComplete.listen((_) {
      _playbackCompleteController.add(null);
    });
  }

  /// Play audio from a local file path
  Future<void> playFile(String filePath) async {
    await _player.play(DeviceFileSource(filePath));
  }

  /// Play audio from a URL
  Future<void> playUrl(String url) async {
    await _player.play(UrlSource(url));
  }

  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
  }

  /// Pause playback
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resume playback
  Future<void> resume() async {
    await _player.resume();
  }

  /// Check if currently playing
  bool get isPlaying => _player.state == PlayerState.playing;

  /// Get current playback position
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  void dispose() {
    _player.dispose();
    _playbackCompleteController.close();
  }
}
