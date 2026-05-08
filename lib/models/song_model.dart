class SongModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? audioUrl;
  final String? audioUrlDirect;
  final Map<String, dynamic>? audioQualities;
  final bool hasFullAudio;
  final String imageUrl;
  final int duration; // seconds
  final String genre;
  final String source; // e.g., 'JioSaavn', 'YouTube'
  final String sourceUrl; // The public URL to the song on the source platform
  final bool isPremium;
  bool isLiked;
  bool isDownloaded;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.audioUrl,
    this.audioUrlDirect,
    this.audioQualities,
    this.hasFullAudio = false,
    required this.imageUrl,
    required this.duration,
    this.genre = '',
    this.source = '',
    this.sourceUrl = '',
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
      audioUrl: json['audio']?.toString(),
      imageUrl: json['album_image'] ?? json['image'] ?? '',
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      genre: (json['musicinfo']?['tags']?['genres'] as List?)
              ?.join(', ') ??
          '',
    );
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id']?.toString() ?? '',
      title: json['name'] ?? json['title'] ?? 'Unknown Title',
      artist: json['artist']?.toString() ?? 'Unknown Artist',
      album: json['album']?.toString() ?? 'Unknown Album',
      audioUrl: json['audioUrl']?.toString(),
      audioUrlDirect: json['audioUrlDirect']?.toString(),
      audioQualities: json['audioQualities'] is Map<String, dynamic>
          ? json['audioQualities'] as Map<String, dynamic>
          : null,
      hasFullAudio: json['hasFullAudio'] ?? false,
      imageUrl: json['imageUrl']?.toString() ?? '',
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      source: json['source']?.toString() ?? '',
      genre: json['genre']?.toString() ?? '',
      sourceUrl: json['sourceUrl']?.toString() ?? '',
      isPremium: json['isPremium'] ?? false,
      isLiked: json['isLiked'] ?? false,
      isDownloaded: json['isDownloaded'] ?? false,
    );
  }

  factory SongModel.fromJioSaavn(Map<String, dynamic> json) {
    String getImageUrl(Map<String, dynamic> map) {
      String getBestUrl(dynamic urls) {
        if (urls is String) {
          return urls.startsWith('http') ? urls : '';
        }

        if (urls is Map) {
          final direct = (urls['link'] ?? urls['url'] ?? '').toString();
          return direct.startsWith('http') ? direct : '';
        }

        if (urls is List && urls.isNotEmpty) {
          final links = urls
              .map((e) => (e is Map ? (e['link'] ?? '') : '').toString())
              .where((u) => u.startsWith('http'))
              .toList();
          if (links.isEmpty) return '';
          return links.last;
        }
        return '';
      }
      final direct = (map['imageUrl'] ?? '').toString();
      if (direct.startsWith('http')) return direct;
      return getBestUrl(map['image']);
    }

    String readAlbum(dynamic album) {
      if (album is String) return album;
      if (album is Map) {
        return (album['name'] ?? album['title'] ?? 'Unknown Album').toString();
      }
      return 'Unknown Album';
    }

    String readArtists(dynamic artists) {
      if (artists is String) return artists;
      if (artists is List) {
        final names = artists
            .map((e) {
              if (e is String) return e;
              if (e is Map) return (e['name'] ?? e['title'] ?? '').toString();
              return '';
            })
            .where((e) => e.trim().isNotEmpty)
            .toList();
        if (names.isNotEmpty) return names.join(', ');
      }
      if (artists is Map) {
        return (artists['name'] ?? artists['title'] ?? 'Unknown Artist').toString();
      }
      return 'Unknown Artist';
    }

    String? readAudioUrl(dynamic audioUrl, dynamic downloadUrl) {
      bool ok(String? u) => u != null && u.startsWith('http');

      if (audioUrl is String && ok(audioUrl)) return audioUrl;

      if (audioUrl is Map) {
        for (final key in ['url', 'link', 'high', '320kbps', '320', '160']) {
          final v = audioUrl[key]?.toString();
          if (ok(v)) return v;
        }
      }

      if (audioUrl is List) {
        final links = audioUrl
            .map((e) => (e is Map ? (e['link'] ?? e['url'] ?? '') : e).toString())
            .where((u) => u.startsWith('http'))
            .toList();
        if (links.isNotEmpty) return links.last;
      }

      if (downloadUrl is List) {
        final ranked = <int, String>{};
        for (final e in downloadUrl) {
          if (e is! Map) continue;
          final quality = int.tryParse((e['quality'] ?? '0').toString()) ?? 0;
          final link = (e['link'] ?? e['url'] ?? '').toString();
          if (link.startsWith('http')) ranked[quality] = link;
        }
        if (ranked.isNotEmpty) {
          final best = ranked.keys.reduce((a, b) => a > b ? a : b);
          return ranked[best];
        }
      }

      if (downloadUrl is Map) {
        final values = [
          downloadUrl['320kbps'],
          downloadUrl['320'],
          downloadUrl['160kbps'],
          downloadUrl['160'],
          downloadUrl['url'],
          downloadUrl['link'],
        ].map((e) => e?.toString()).toList();

        for (final v in values) {
          if (ok(v)) return v;
        }
      }

      if (downloadUrl is String && ok(downloadUrl)) return downloadUrl;

      return null;
    }

    Map<String, dynamic>? readAudioQualities(dynamic downloadUrl) {
      if (downloadUrl is! List) return null;

      final out = <String, dynamic>{};
      for (final e in downloadUrl) {
        if (e is! Map) continue;
        final q = (e['quality'] ?? '').toString();
        final link = (e['link'] ?? e['url'] ?? '').toString();
        if (!link.startsWith('http')) continue;

        if (q == '48') out['basic'] = {'url': link};
        if (q == '96') out['normal'] = {'url': link};
        if (q == '160') out['high'] = {'url': link};
        if (q == '320') out['ultra_hd'] = {'url': link};
      }
      return out.isEmpty ? null : out;
    }

    final resolvedAudioUrl = readAudioUrl(json['audioUrl'], json['downloadUrl']);
    final resolvedQualities =
        (json['audioQualities'] is Map<String, dynamic>)
            ? json['audioQualities'] as Map<String, dynamic>
            : readAudioQualities(json['downloadUrl']);

    return SongModel(
      id: 'jiosaavn_${json['id'] ?? ''}',
      title: json['name'] ?? json['title'] ?? 'Unknown Title',
      artist: json['artist']?.toString().trim().isNotEmpty == true
          ? json['artist'].toString()
          : readArtists(json['primaryArtists']),
      album: readAlbum(json['album']),
      audioUrl: resolvedAudioUrl,
      audioUrlDirect: json['audioUrlDirect']?.toString(),
      audioQualities: resolvedQualities,
      hasFullAudio: json['hasFullAudio'] ?? false,
      imageUrl: getImageUrl(json),
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      source: 'JioSaavn',
      sourceUrl: json['url'] ?? '',
    );
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'audioUrl': audioUrl,
      'audioUrlDirect': audioUrlDirect,
      'audioQualities': audioQualities,
      'hasFullAudio': hasFullAudio,
      'imageUrl': imageUrl,
      'duration': duration,
      'genre': genre,
      'source': source,
      'sourceUrl': sourceUrl,
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
      audioUrlDirect: audioUrlDirect,
      audioQualities: audioQualities,
      hasFullAudio: hasFullAudio,
      imageUrl: imageUrl,
      duration: duration,
      genre: genre,
      source: source,
      sourceUrl: sourceUrl,
      isPremium: isPremium,
      isLiked: isLiked ?? this.isLiked,
      isDownloaded: isDownloaded ?? this.isDownloaded,
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
      if (urls is String) return urls.startsWith('http') ? urls : '';
      if (urls is Map) {
        final u = (urls['link'] ?? urls['url'] ?? '').toString();
        return u.startsWith('http') ? u : '';
      }
      if (urls is List && urls.isNotEmpty) {
        final links = urls
            .map((e) => (e is Map ? (e['link'] ?? e['url'] ?? '') : e).toString())
            .where((u) => u.startsWith('http'))
            .toList();
        if (links.isEmpty) return '';
        return links.last;
      }
      return '';
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
      if (urls is String) return urls.startsWith('http') ? urls : '';
      if (urls is Map) {
        final u = (urls['link'] ?? urls['url'] ?? '').toString();
        return u.startsWith('http') ? u : '';
      }
      if (urls is List && urls.isNotEmpty) {
        final links = urls
            .map((e) => (e is Map ? (e['link'] ?? e['url'] ?? '') : e).toString())
            .where((u) => u.startsWith('http'))
            .toList();
        if (links.isEmpty) return '';
        return links.last;
      }
      return '';
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
