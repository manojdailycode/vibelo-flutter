class SongModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String audioUrl;
  final String imageUrl;
  final int duration; // seconds
  final String genre;
  final bool isPremium;
  bool isLiked;
  bool isDownloaded;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.audioUrl,
    required this.imageUrl,
    required this.duration,
    this.genre = '',
    this.isPremium = false,
    this.isLiked = false,
    this.isDownloaded = false,
  });

  String get durationString {
    final m = (duration ~/ 60).toString().padLeft(2, '0');
    final s = (duration % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  factory SongModel.fromJamendo(Map<String, dynamic> json) {
    return SongModel(
      id: json['id']?.toString() ?? '',
      title: json['name'] ?? 'Unknown Title',
      artist: json['artist_name'] ?? 'Unknown Artist',
      album: json['album_name'] ?? 'Unknown Album',
      audioUrl: json['audio'] ?? '',
      imageUrl: json['album_image'] ?? json['image'] ?? '',
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      genre: (json['musicinfo']?['tags']?['genres'] as List?)
              ?.join(', ') ??
          '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'duration': duration,
      'genre': genre,
      'isPremium': isPremium,
      'isLiked': isLiked,
    };
  }

  SongModel copyWith({bool? isLiked, bool? isDownloaded}) {
    return SongModel(
      id: id,
      title: title,
      artist: artist,
      album: album,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      duration: duration,
      genre: genre,
      isPremium: isPremium,
      isLiked: isLiked ?? this.isLiked,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}

class PlaylistModel {
  final String id;
  final String name;
  final String? coverUrl;
  final List<SongModel> songs;
  final String createdBy;
  final bool isPublic;

  PlaylistModel({
    required this.id,
    required this.name,
    this.coverUrl,
    this.songs = const [],
    required this.createdBy,
    this.isPublic = false,
  });

  int get totalDuration => songs.fold(0, (sum, s) => sum + s.duration);
}
