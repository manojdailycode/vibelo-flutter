import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class LyricsService {
  // Returns synced LRC lyrics or plain text
  // LRCLIB is 100% free, no API key, has most Hindi/Telugu songs
  
  Future<LyricsResult?> getLyrics({
    required String title,
    required String artist,
    String album = '',
    int duration = 0,
  }) async {
    try {
      // Try synced first
      final synced = await _getSynced(title, artist, duration);
      if (synced != null) return synced;
      
      // Fallback: plain text
      return await _getPlain(title, artist);
    } catch (_) {
      return null;
    }
  }

  Future<LyricsResult?> _getSynced(
      String title, String artist, int duration) async {
    final url = Uri.parse(
      '${ApiConfig.lrclibBase}/get'
      '?track_name=${Uri.encodeComponent(title)}'
      '&artist_name=${Uri.encodeComponent(artist)}'
      '&duration=$duration',
    );
    final res = await http.get(url).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    
    final data = json.decode(res.body);
    final syncedLrc = data['syncedLyrics'] as String?;
    final plainText = data['plainLyrics'] as String?;
    
    if (syncedLrc != null && syncedLrc.isNotEmpty) {
      return LyricsResult(
        lines: _parseLRC(syncedLrc),
        isSynced: true,
      );
    }
    if (plainText != null && plainText.isNotEmpty) {
      return LyricsResult(
        lines: plainText.split('\n')
            .map((l) => LyricLine(time: Duration.zero, text: l))
            .toList(),
        isSynced: false,
      );
    }
    return null;
  }

  Future<LyricsResult?> _getPlain(String title, String artist) async {
    final url = Uri.parse(
      '${ApiConfig.lrclibBase}/search'
      '?track_name=${Uri.encodeComponent(title)}'
      '&artist_name=${Uri.encodeComponent(artist)}',
    );
    final res = await http.get(url).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    
    final List data = json.decode(res.body);
    if (data.isEmpty) return null;
    
    final plain = data.first['plainLyrics'] as String? ?? '';
    if (plain.isEmpty) return null;
    
    return LyricsResult(
      lines: plain.split('\n')
          .map((l) => LyricLine(time: Duration.zero, text: l))
          .toList(),
      isSynced: false,
    );
  }

  List<LyricLine> _parseLRC(String lrc) {
    final lines = <LyricLine>[];
    for (final line in lrc.split('\n')) {
      // Format: [mm:ss.xx] lyric text
      final match = RegExp(r'\[(\d+):(\d+)\.(\d+)\](.*)').firstMatch(line);
      if (match == null) continue;
      final min = int.parse(match.group(1)!);
      final sec = int.parse(match.group(2)!);
      final ms  = int.parse(match.group(3)!.padRight(3, '0').substring(0, 3));
      final text = match.group(4)!.trim();
      lines.add(LyricLine(
        time: Duration(minutes: min, seconds: sec, milliseconds: ms),
        text: text,
      ));
    }
    return lines;
  }
}

class LyricsResult {
  final List<LyricLine> lines;
  final bool isSynced;
  LyricsResult({required this.lines, required this.isSynced});
}

class LyricLine {
  final Duration time;
  final String text;
  LyricLine({required this.time, required this.text});
}