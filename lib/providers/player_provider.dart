import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_handler.dart';
import '../models/song_model.dart';
import '../services/youtube_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlayerProvider extends ChangeNotifier {
  final VibeleAudioHandler _handler;

  // FIX: create a single YoutubeExplode instance and reuse it.
  // Creating a new instance per song leaks resources.
  final YoutubeExplode _yt = YoutubeExplode();

  SongModel? _currentSong;
  List<SongModel> _queue    = [];
  int _queueIndex           = 0;

  bool _isPlaying           = false;
  bool _isShuffled          = false;
  bool _isLooping           = false;
  bool _isLoadingSong       = false;
  bool _isBuffering         = false;
  String? _playbackError;
  String _selectedQuality = 'high';

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  int _sleepMinutes     = 0;
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

    _handler.player.processingStateStream.listen((state) {
      _isBuffering = state == ProcessingState.loading ||
          state == ProcessingState.buffering;
      notifyListeners();
    });
  }

  SongModel?        get currentSong    => _currentSong;
  List<SongModel>   get queue          => _queue;
  int               get queueIndex     => _queueIndex;
  bool              get isPlaying      => _isPlaying;
  bool              get isShuffled     => _isShuffled;
  bool              get isLooping      => _isLooping;
  bool              get isLoading      => _isLoadingSong || _isBuffering;
  bool              get hasSong        => _currentSong != null;
  Duration          get position       => _position;
  Duration          get duration       => _duration;
  int               get sleepMinutes   => _sleepMinutes;
  bool              get hasError       => _playbackError != null;
  String?           get playbackError  => _playbackError;
  String            get selectedQuality => _selectedQuality;

  static const Map<String, String> _qualityKeyByLabel = {
    'Low': 'basic',
    'Normal': 'normal',
    'High': 'high',
    'Ultra HD': 'ultra_hd',
  };

  void clearError() {
    _playbackError = null;
    notifyListeners();
  }

  double get progress {
    if (_duration.inSeconds == 0) return 0;
    return (_position.inSeconds / _duration.inSeconds).clamp(0.0, 1.0);
  }

  // ── Play a song ─────────────────────────────────────────────────────────
  Future<void> playSong(SongModel song, {List<SongModel>? queue}) async {
    _isLoadingSong  = true;
    _playbackError  = null;
    notifyListeners();

    _currentSong = song;
    if (queue != null) {
      _queue      = queue;
      _queueIndex = queue.indexWhere((s) => s.id == song.id);
      if (_queueIndex < 0) _queueIndex = 0;
    } else if (!_queue.any((s) => s.id == song.id)) {
      _queue.add(song);
      _queueIndex = _queue.length - 1;
    }

    try {
      if (song.audioUrl == null || song.audioUrl!.isEmpty) {
        _playbackError = 'Audio unavailable for this song.';
        return;
      }

      String audioUrl = song.audioUrl!;

      // ── Resolve YouTube → real audio stream URL ──────────────────────────
      if (YouTubeService.isYouTubeUrl(audioUrl)) {
        final videoId = YouTubeService.extractVideoId(audioUrl);
        if (videoId == null || videoId.isEmpty) {
          throw Exception('Could not extract YouTube video ID from: $audioUrl');
        }

        debugPrint('PlayerProvider: resolving YouTube stream for $videoId');

        // youtube_explode_dart does NOT need a v3 API key — it scrapes YouTube
        // directly, so playback works even when the Data API quota is exhausted.
        StreamManifest manifest;
        try {
          manifest = await _yt.videos.streamsClient
              .getManifest(videoId)
              .timeout(const Duration(seconds: 20));
        } catch (e) {
          throw Exception(
              'YouTube stream fetch failed for $videoId — '
              'check your internet connection. ($e)');
        }

        final audioStreams = manifest.audioOnly;
        if (audioStreams.isEmpty) {
          throw Exception('No audio-only stream found for YouTube video $videoId');
        }

        // Some YouTube CDN URLs return 403 on specific devices/networks.
        // Try multiple audio-only variants from high->low bitrate.
        final sorted = audioStreams.toList()
          ..sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));

        Object? lastError;
        bool started = false;

        for (final stream in sorted.take(6)) {
          final candidateUrl = stream.url.toString();
          try {
            final item = MediaItem(
              id:       candidateUrl,
              title:    song.title,
              artist:   song.artist,
              album:    song.album,
              artUri:   Uri.tryParse(song.imageUrl),
              duration: Duration(seconds: song.duration),
            );

            await _handler.playFromUrl(candidateUrl, item);
            audioUrl = candidateUrl;
            started = true;
            debugPrint('PlayerProvider: resolved and started → $audioUrl');
            break;
          } catch (e) {
            lastError = e;
            debugPrint('PlayerProvider: stream candidate failed → $e');
          }
        }

        if (!started) {
          throw Exception('YouTube streams blocked/expired for $videoId. Last error: $lastError');
        }
      }
      // ─────────────────────────────────────────────────────────────────────

      // If the source is not YouTube (or YouTube was not pre-started above),
      // play via normal path using backend-provided audioUrl.
      if (!YouTubeService.isYouTubeUrl(song.audioUrl ?? '')) {
      final item = MediaItem(
        id:       audioUrl,
        title:    song.title,
        artist:   song.artist,
        album:    song.album,
        artUri:   Uri.tryParse(song.imageUrl),
        duration: Duration(seconds: song.duration),
      );

      await _handler.playFromUrl(audioUrl, item);
      }
    } catch (e) {
      _playbackError = e.toString();
      debugPrint('PlayerProvider.playSong ERROR: $e');
    } finally {
      // FIX: always clear the loading flag — prevents the spinner sticking.
      _isLoadingSong = false;
      notifyListeners();
    }
  }

  Future<void> setAudioQualityLabel(String label) async {
    final key = _qualityKeyByLabel[label];
    if (key == null) return;
    _selectedQuality = key;
    notifyListeners();

    final song = _currentSong;
    if (song == null) return;
    final nextUrl = _resolveQualityUrl(song);
    if (nextUrl == null || nextUrl.isEmpty) return;

    final item = MediaItem(
      id: nextUrl,
      title: song.title,
      artist: song.artist,
      album: song.album,
      artUri: Uri.tryParse(song.imageUrl),
      duration: Duration(seconds: song.duration),
    );

    await _handler.playFromUrl(nextUrl, item);
  }

  String? _resolveQualityUrl(SongModel song) {
    final q = song.audioQualities;
    if (q == null) return song.audioUrl;

    String? read(String key) => (q[key] is Map)
        ? (q[key]['url']?.toString())
        : null;

    return read(_selectedQuality) ?? song.audioUrl;
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
      await _handler
          .seek(Duration(seconds: (progress * _duration.inSeconds).round()));
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
      _isShuffled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
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

  // ── Sleep Timer ──────────────────────────────────────────────────────────
  void setSleepTimer(int minutes) {
    _sleepMinutes = minutes;
    if (minutes > 0) {
      _sleepTime =
          DateTime.now().add(Duration(minutes: minutes));
      Future.delayed(Duration(minutes: minutes), () {
        _handler.pause();
        _sleepMinutes = 0;
        _sleepTime    = null;
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

  @override
  void dispose() {
    _yt.close();
    super.dispose();
  }
}