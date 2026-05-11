class SongModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String audioUrl;
  final String imageUrl;
  final int duration; // seconds
  final String genre;
  final String source; // e.g., 'JioSaavn', 'YouTube'
  final String sourceUrl; // The public URL to the song on the source platform
  final bool isPremium;
  bool isLiked;
  bool isDownloaded;
  final Map<String, dynamic>? audioQualities;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.audioUrl,
    required this.imageUrl,
    required this.duration,
    this.genre = '',
    this.source = '',
    this.sourceUrl = '',
    this.isPremium = false,
    this.isLiked = false,
    this.isDownloaded = false,
    this.audioQualities,
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
      genre: (json['musicinfo']?['tags']?['genres'] as List?)?.join(', ') ?? '',
      audioQualities: json['audioQualities'] as Map<String, dynamic>?,
    );
  }

  factory SongModel.fromJioSaavn(Map<String, dynamic> json) {
    // Helper to get the highest quality URL from a list of links
    String getBestUrl(dynamic urls) {
      if (urls is List && urls.isNotEmpty) {
        return (urls.last['link'] ?? '').toString();
      }
      return (urls is String) ? urls : '';
    }

    return SongModel(
      id: 'jiosaavn_${json['id'] ?? ''}',
      title: json['name'] ?? json['title'] ?? 'Unknown Title',
      artist: json['primaryArtists'] ?? 'Unknown Artist',
      album: json['album']?['name'] ?? 'Unknown Album',
      audioUrl: getBestUrl(json['downloadUrl']),
      imageUrl: getBestUrl(json['image']),
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      source: 'JioSaavn',
      sourceUrl: json['url'] ?? '',
      audioQualities: json['audioQualities'] as Map<String, dynamic>?,
    );
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Unknown Title',
      artist: map['artist'] ?? 'Unknown Artist',
      album: map['album'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      duration: map['duration'] ?? 0,
      source: map['source'] ?? '',
      genre: map['genre'] ?? '',
      sourceUrl: map['sourceUrl'] ?? '',
      isPremium: map['isPremium'] ?? false,
      isLiked: map['isLiked'] ?? false,
      audioQualities: map['audioQualities'] as Map<String, dynamic>?,
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
      'source': source,
      'sourceUrl': sourceUrl,
      'isPremium': isPremium,
      'isLiked': isLiked,
      if (audioQualities != null) 'audioQualities': audioQualities,
    };
  }

  SongModel copyWith({bool? isLiked, bool? isDownloaded, Map<String, dynamic>? audioQualities}) {
    return SongModel(
      id: id,
      title: title,
      artist: artist,
      album: album,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      duration: duration,
      genre: genre,
      source: source,
      sourceUrl: sourceUrl,
      isPremium: isPremium,
      isLiked: isLiked ?? this.isLiked,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      audioQualities: audioQualities ?? this.audioQualities,
    );
  }
}

class AlbumModel {
  final String id;
  final String title;
  final String? artist;
  final String imageUrl;
  final String year;
  final String source;
  final String sourceUrl;

  AlbumModel({
    required this.id,
    required this.title,
    this.artist,
    required this.imageUrl,
    required this.year,
    required this.source,
    required this.sourceUrl,
  });

  factory AlbumModel.fromJioSaavn(Map<String, dynamic> json) {
    String getBestUrl(dynamic urls) {
      if (urls is List && urls.isNotEmpty) return (urls.last['link'] ?? '').toString();
      return (urls is String) ? urls : '';
    }

    return AlbumModel(
      id: 'jiosaavn_${json['id'] ?? ''}',
      title: json['name'] ?? json['title'] ?? 'Unknown Album',
      artist: json['primaryArtists'] ?? json['artistName'] ?? '',
      imageUrl: getBestUrl(json['image']),
      year: json['year']?.toString() ?? '',
      source: 'JioSaavn',
      sourceUrl: json['url'] ?? '',
    );
  }

  factory AlbumModel.fromDeezer(Map<String, dynamic> json) {
    return AlbumModel(
      id: 'deezer_${json['id'] ?? ''}',
      title: json['title'] ?? 'Unknown Album',
      artist: json['artist']?['name'] ?? '',
      imageUrl: json['cover_big'] ?? json['cover_medium'] ?? '',
      year: '', // Deezer search doesn't provide year
      source: 'Deezer',
      sourceUrl: json['link'] ?? '',
    );
  }

  factory AlbumModel.fromAudius(Map<String, dynamic> json) {
    final artwork = json['artwork'];
    String imageUrl = '';
    if (artwork is Map) {
      imageUrl = artwork['480x480'] ?? artwork['150x150'] ?? '';
    }
    return AlbumModel(
      id: 'audius_${json['id'] ?? ''}',
      title: json['playlist_name'] ?? 'Unknown Album',
      artist: json['user']?['name'] ?? '',
      imageUrl: imageUrl,
      year: json['year']?.toString() ?? '',
      source: 'Audius',
      sourceUrl: json['permalink'] ?? '',
    );
  }

  factory AlbumModel.fromJamendo(Map<String, dynamic> json) {
    return AlbumModel(
      id: 'jamendo_${json['id'] ?? ''}',
      title: json['name'] ?? 'Unknown Album',
      artist: json['artist_name'] ?? '',
      imageUrl: json['image'] ?? '',
      year: (json['releasedate'] ?? '').toString().split('-').first,
      source: 'Jamendo',
      sourceUrl: json['shareurl'] ?? '',
    );
  }
}

class ArtistModel {
  final String id;
  final String name;
  final String imageUrl;
  final String source;
  final String sourceUrl;

  ArtistModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.source,
    required this.sourceUrl,
  });

  factory ArtistModel.fromJioSaavn(Map<String, dynamic> json) {
    String getBestUrl(dynamic urls) {
      if (urls is List && urls.isNotEmpty) return (urls.last['link'] ?? '').toString();
      return (urls is String) ? urls : '';
    }

    return ArtistModel(
      id: 'jiosaavn_${json['id'] ?? ''}',
      name: json['name'] ?? json['title'] ?? 'Unknown Artist',
      imageUrl: getBestUrl(json['image']),
      source: 'JioSaavn',
      sourceUrl: json['url'] ?? '',
    );
  }

  factory ArtistModel.fromDeezer(Map<String, dynamic> json) {
    return ArtistModel(
      id: 'deezer_${json['id'] ?? ''}',
      name: json['name'] ?? 'Unknown Artist',
      imageUrl: json['picture_big'] ?? json['picture_medium'] ?? '',
      source: 'Deezer',
      sourceUrl: json['link'] ?? '',
    );
  }

  factory ArtistModel.fromAudius(Map<String, dynamic> json) {
    final artwork = json['profile_picture'];
    String imageUrl = '';
    if (artwork is Map) {
      imageUrl = artwork['480x480'] ?? artwork['150x150'] ?? '';
    }
    return ArtistModel(
      id: 'audius_${json['id'] ?? ''}',
      name: json['name'] ?? 'Unknown Artist',
      imageUrl: imageUrl,
      source: 'Audius',
      sourceUrl: json['permalink'] ?? '',
    );
  }

  factory ArtistModel.fromJamendo(Map<String, dynamic> json) {
    return ArtistModel(
      id: 'jamendo_${json['id'] ?? ''}',
      name: json['name'] ?? 'Unknown Artist',
      imageUrl: json['image'] ?? '',
      source: 'Jamendo',
      sourceUrl: json['shareurl'] ?? '',
    );
  }
}

class PlaylistModel {
  final String id;
  final String name;
  final String? coverUrl;
  final List<SongModel> songs;
  final String createdBy;
  final String source;
  final String sourceUrl;
  final bool isPublic;

  PlaylistModel({
    required this.id,
    required this.name,
    this.coverUrl,
    this.songs = const [],
    required this.createdBy,
    this.source = '',
    this.sourceUrl = '',
    this.isPublic = false,
  });

  int get totalDuration => songs.fold(0, (sum, s) => sum + s.duration);
}

/// A container for all results from a multi-type search.
class SearchResults {
  final List<SongModel> songs;
  final List<AlbumModel> albums;
  final List<ArtistModel> artists;
  final List<PlaylistModel> playlists;

  SearchResults({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
  });
}
