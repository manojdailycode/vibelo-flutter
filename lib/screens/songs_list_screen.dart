import 'package:flutter/material.dart';
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
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: VColors.primary),
            );
          }
          if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
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
                  itemBuilder: (_, i) =>
                      SongTile(song: songs[i], songs: songs),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
