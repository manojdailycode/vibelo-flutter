import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

// Background audio handler — works when screen is off, in notification
class VibeleAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  VibeleAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    _player.currentIndexStream.listen((index) {
      if (index != null && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  AudioPlayer get player => _player;

  // ── Play from URL ────────────────────────────────
  Future<void> playFromUrl(String url, MediaItem item) async {
    mediaItem.add(item);
    await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
    await _player.play();
  }

  // ── Controls ─────────────────────────────────────
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> setLoopMode(bool loop) async {
    await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(
      shuffleMode == AudioServiceShuffleMode.all,
    );
  }

  // ── Stream helpers ───────────────────────────────
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<double> get speedStream => _player.speedStream;

  bool get playing => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  // ── Build lock-screen / notification controls ────
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }
}
