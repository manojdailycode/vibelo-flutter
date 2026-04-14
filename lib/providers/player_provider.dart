import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_handler.dart';
import '../models/song_model.dart';

class PlayerProvider extends ChangeNotifier {
  final VibeleAudioHandler _handler;

  SongModel? _currentSong;
  List<SongModel> _queue = [];
  int _queueIndex = 0;

  bool _isPlaying = false;
  bool _isShuffled = false;
  bool _isLooping = false;

  // FIX: separate "loading a new song" from "buffering"
  bool _isLoadingSong = false; // true only while calling playSong()
  bool _isBuffering = false;   // true while audio engine is buffering

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Sleep timer
  int _sleepMinutes = 0;
  DateTime? _sleepTime;

  PlayerProvider(this._handler) {
    _handler.playingStream.listen((v) {
      _isPlaying = v;
      notifyListeners();
    });

    _handler.positionStream.listen((d) {
      _position = d;
      notifyListeners();
    });

    _handler.durationStream.listen((d) {
      _duration = d ?? Duration.zero;
      notifyListeners();
    });

    // FIX: track buffering state from the audio engine
    _handler.player.processingStateStream.listen((state) {
      _isBuffering = state == ProcessingState.loading ||
          state == ProcessingState.buffering;
      notifyListeners();
    });
  }

  SongModel? get currentSong => _currentSong;
  List<SongModel> get queue => _queue;
  int get queueIndex => _queueIndex;
  bool get isPlaying => _isPlaying;
  bool get isShuffled => _isShuffled;
  bool get isLooping => _isLooping;

  /// Show spinner only while loading a new song OR while buffering.
  /// Once playing, both become false and the play/pause icon shows correctly.
  bool get isLoading => _isLoadingSong || _isBuffering;

  bool get hasSong => _currentSong != null;
  Duration get position => _position;
  Duration get duration => _duration;
  int get sleepMinutes => _sleepMinutes;

  double get progress {
    if (_duration.inSeconds == 0) return 0;
    return (_position.inSeconds / _duration.inSeconds).clamp(0.0, 1.0);
  }

  // ── Play a song ──────────────────────────────────
  Future<void> playSong(SongModel song, {List<SongModel>? queue}) async {
    _isLoadingSong = true;
    notifyListeners();

    _currentSong = song;
    if (queue != null) {
      _queue = queue;
      _queueIndex = queue.indexWhere((s) => s.id == song.id);
    } else if (!_queue.any((s) => s.id == song.id)) {
      _queue.add(song);
      _queueIndex = _queue.length - 1;
    }

    final item = MediaItem(
      id: song.audioUrl,
      title: song.title,
      artist: song.artist,
      album: song.album,
      artUri: Uri.tryParse(song.imageUrl),
      duration: Duration(seconds: song.duration),
    );

    // FIX: always clear isLoadingSong in finally so spinner never gets stuck
    try {
      await _handler.playFromUrl(song.audioUrl, item);
    } catch (e) {
      debugPrint('PlayerProvider.playSong error: $e');
    } finally {
      _isLoadingSong = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _handler.pause();
    } else {
      await _handler.play();
    }
  }

  Future<void> seekTo(Duration position) async {
    await _handler.seek(position);
  }

  Future<void> seekToProgress(double progress) async {
    if (_duration.inSeconds > 0) {
      await _handler.seek(
        Duration(seconds: (progress * _duration.inSeconds).round()),
      );
    }
  }

  Future<void> skipNext() async {
    if (_queueIndex < _queue.length - 1) {
      _queueIndex++;
      await playSong(_queue[_queueIndex]);
    }
  }

  Future<void> skipPrevious() async {
    if (_position.inSeconds > 3) {
      await _handler.seek(Duration.zero);
    } else if (_queueIndex > 0) {
      _queueIndex--;
      await playSong(_queue[_queueIndex]);
    }
  }

  Future<void> toggleShuffle() async {
    _isShuffled = !_isShuffled;
    await _handler.setShuffleMode(
      _isShuffled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
    notifyListeners();
  }

  Future<void> toggleLoop() async {
    _isLooping = !_isLooping;
    await _handler.setLoopMode(_isLooping);
    notifyListeners();
  }

  void addToQueue(SongModel song) {
    if (!_queue.any((s) => s.id == song.id)) {
      _queue.add(song);
      notifyListeners();
    }
  }

  void removeFromQueue(int index) {
    _queue.removeAt(index);
    notifyListeners();
  }

  // ── Sleep Timer ──────────────────────────────────
  void setSleepTimer(int minutes) {
    _sleepMinutes = minutes;
    if (minutes > 0) {
      _sleepTime = DateTime.now().add(Duration(minutes: minutes));
      Future.delayed(Duration(minutes: minutes), () {
        _handler.pause();
        _sleepMinutes = 0;
        _sleepTime = null;
        notifyListeners();
      });
    } else {
      _sleepTime = null;
    }
    notifyListeners();
  }

  String? get sleepTimeRemaining {
    if (_sleepTime == null) return null;
    final remaining = _sleepTime!.difference(DateTime.now());
    if (remaining.isNegative) return null;
    final m = remaining.inMinutes;
    final s = remaining.inSeconds % 60;
    return '${m}m ${s}s';
  }
}
