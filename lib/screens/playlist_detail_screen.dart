import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import '../providers/player_provider.dart';
import 'player_screen.dart';
import '../services/youtube_service.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Map<String, dynamic> playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final songMaps = (playlist['songs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final songs = songMaps.map((map) => SongModel.fromMap(map)).toList();
    final playlistName = playlist['name'] ?? 'Playlist';
    final playlistEmoji = playlist['emoji'] ?? '🎵';

    return Scaffold(
      backgroundColor: VColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            stretch: true,
            backgroundColor: VColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                playlistName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: VColors.textPri,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: VColors.primaryGrad,
                    ),
                  ),
                  Positioned(
                    top: 100,
                    left: 30,
                    child: Text(
                      playlistEmoji,
                      style: const TextStyle(fontSize: 80, shadows: [
                        Shadow(blurRadius: 20, color: Colors.black26)
                      ]),
                    ),
                  ),
                  // Frosted glass effect
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(color: Colors.black.withValues(alpha: 0.1)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.music_note_rounded, color: VColors.textSec, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${songs.length} songs',
                    style: GoogleFonts.poppins(color: VColors.textSec),
                  ),
                  const Spacer(),
                  if (songs.isNotEmpty) ...[
                    // Shuffle Button
                    IconButton(
                      onPressed: () {
                        final playableSongs = songs.where((s) => !YouTubeService.isYouTubeUrl(s.audioUrl)).toList();
                        if (playableSongs.isNotEmpty) {
                          final shuffled = List<SongModel>.from(playableSongs)..shuffle();
                          context.read<PlayerProvider>().playSong(shuffled.first, queue: shuffled);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const PlayerScreen(),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('This playlist only contains YouTube videos.', style: GoogleFonts.poppins()),
                            backgroundColor: VColors.surface,
                          ));
                        }
                      },
                      icon: const Icon(Icons.shuffle_rounded),
                      style: IconButton.styleFrom(
                        foregroundColor: VColors.textSec,
                        backgroundColor: VColors.cardLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Play All Button
                    ElevatedButton.icon(
                      onPressed: () {
                        final playableSongs = songs.where((s) => s.audioUrl != null && s.audioUrl!.isNotEmpty && !YouTubeService.isYouTubeUrl(s.audioUrl)).toList();
                        if (playableSongs.isNotEmpty) {
                          context.read<PlayerProvider>().playSong(playableSongs.first, queue: playableSongs);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const PlayerScreen(),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('This playlist only contains YouTube videos.', style: GoogleFonts.poppins()),
                            backgroundColor: VColors.surface,
                          ));
                        }
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: Text('Play All', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
          if (songs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.queue_music_rounded, color: VColors.textMuted, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      'No songs yet',
                      style: GoogleFonts.poppins(
                        color: VColors.textPri,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add songs to this playlist to see them here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: VColors.textSec, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: SongTile(song: songs[index], songs: songs),
                    );
                  },
                  childCount: songs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}