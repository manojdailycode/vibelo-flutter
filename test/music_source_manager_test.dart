import 'package:flutter_test/flutter_test.dart';
import 'package:vibelo/models/song_model.dart';
import 'package:vibelo/providers/music_source_manager.dart';
import 'package:vibelo/services/jiosaavn_service.dart';
import 'package:vibelo/services/youtube_service.dart';

class FakeJioSaavnService extends JioSaavnService {
  @override
  JioSaavnErrorType? get lastError => JioSaavnErrorType.notFound;

  @override
  Future<List<SongModel>> searchSongs(String query, {int limit = 20}) async {
    return [];
  }

  @override
  Future<List<AlbumModel>> searchAlbums(String query, {int limit = 20}) async {
    return [];
  }

  @override
  Future<List<ArtistModel>> searchArtists(String query, {int limit = 20}) async {
    return [];
  }
}

class FakeYouTubeService extends YouTubeService {
  @override
  Future<List<SongModel>> search(String query, {int limit = 20}) async {
    return [
      SongModel(
        id: 'yt_test_1',
        title: 'Fallback Song',
        artist: 'YouTube Artist',
        album: 'Fallback Album',
        audioUrl: 'youtube://test',
        imageUrl: 'https://example.com/image.png',
        duration: 120,
        source: 'YouTube',
      ),
    ];
  }
}

void main() {
  test('searchAll falls back to YouTube when JioSaavn returns no songs', () async {
    final manager = MusicSourceManager(
      jiosaavn: FakeJioSaavnService(),
      youtube: FakeYouTubeService(),
    );

    final results = await manager.searchAll('telugu', limitPerType: 5);

    expect(results.songs, hasLength(1));
    expect(results.songs.first.source, equals('YouTube'));
    expect(results.songs.first.title, equals('Fallback Song'));
  });
}
