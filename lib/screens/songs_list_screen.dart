import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/song_model.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import '../screens/player_screen.dart';

/// Reusable screen for Mood songs, Genre songs, See All
class SongsListScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final Future<List<SongModel>> Function() loader;
  final String? emoji;

  const SongsListScreen({
    super.key,
    required this.title,
    required this.loader,
    this.subtitle = '',
    this.emoji,
  });

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VColors.bg,
      appBar: AppBar(
        backgroundColor: VColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: VColors.textPri),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
            ],
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: VColors.textPri,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<SongModel>>(
        future: loader(),
        builder: (context, snap) {
          _log('[SongsListScreen:$title] connectionState=${snap.connectionState}');
          _log('[SongsListScreen:$title] hasData=${snap.hasData} hasError=${snap.hasError}');
          _log('[SongsListScreen:$title] snapshot.data.length=${snap.data?.length ?? -1}');
          if (snap.error != null) {
            _log('[SongsListScreen:$title] snapshot.error=${snap.error}');
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: VColors.primary),
            );
          }

          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.redAccent, size: 54),
                    const SizedBox(height: 10),
                    Text(
                      'Failed to load songs',
                      style: GoogleFonts.poppins(
                        color: VColors.textPri,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snap.error}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: VColors.textSec,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snap.hasData || snap.data == null || snap.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_off_rounded,
                      color: VColors.textMuted, size: 60),
                  const SizedBox(height: 12),
                  Text(
                    'No songs found',
                    style: GoogleFonts.poppins(
                        color: VColors.textSec, fontSize: 15),
                  ),
                ],
              ),
            );
          }
          final songs = snap.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${songs.length} songs',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: VColors.textSec),
                    ),
                    // Play all button
                    GestureDetector(
                      onTap: () {
                        context
                            .read<PlayerProvider>()
                            .playSong(songs.first, queue: songs);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const PlayerScreen(),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [VColors.primary, Color(0xFF4A90D9)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'Play All',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: songs.length,
                  itemBuilder: (_, i) {
                    final s = songs[i];
                    _log(
                      '[SongsListScreen:$title] itemBuilder index=$i id=${s.id} title=${s.title} artist=${s.artist} audioUrl=${s.audioUrl} imageUrl=${s.imageUrl}',
                    );
                    return SongTile(song: s, songs: songs);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
