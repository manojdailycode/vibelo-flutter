import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../providers/player_provider.dart';
import '../providers/auth_provider.dart';
import '../models/song_model.dart';
import '../screens/player_screen.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final List<SongModel> songs;

  const SongTile({super.key, required this.song, required this.songs});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final auth = context.watch<AuthProvider>();
    final isPlaying = player.currentSong?.id == song.id && player.isPlaying;
    final isLiked = auth.isLiked(song.id);

    return GestureDetector(
      onTap: () {
        player.playSong(song, queue: songs);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const PlayerScreen(),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              isPlaying ? VColors.primary.withValues(alpha: 0.1) : VColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPlaying
                ? VColors.primary.withValues(alpha: 0.4)
                : VColors.divider,
          ),
        ),
        child: Row(
          children: [
            // Album Art
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: song.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: song.imageUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _Placeholder(),
                          errorWidget: (_, __, ___) => _Placeholder(),
                        )
                      : _Placeholder(),
                ),
                if (isPlaying)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.volume_up_rounded,
                        color: VColors.primary, size: 22),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Song Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w500,
                      color: isPlaying ? VColors.primary : VColors.textPri,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: VColors.textSec),
                  ),
                ],
              ),
            ),

            // Duration
            Text(
              song.durationString,
              style:
                  GoogleFonts.poppins(fontSize: 12, color: VColors.textMuted),
            ),
            const SizedBox(width: 4),

            // Like button
            IconButton(
              onPressed: () => auth.toggleLike(song.id),
              icon: Icon(
                isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isLiked ? VColors.accent : VColors.textMuted,
                size: 20,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),

            // More options
            IconButton(
              onPressed: () => _showOptions(context, song),
              icon: const Icon(Icons.more_vert_rounded,
                  color: VColors.textMuted, size: 20),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, SongModel song) {
    final player = context.read<PlayerProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: VColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded,
                  color: VColors.textSec),
              title: Text('Add to Queue',
                  style: GoogleFonts.poppins(color: VColors.textPri)),
              onTap: () {
                player.addToQueue(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Added to queue', style: GoogleFonts.poppins()),
                    backgroundColor: VColors.primary,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_check_rounded,
                  color: VColors.textSec),
              title: Text('Add to Playlist',
                  style: GoogleFonts.poppins(color: VColors.textPri)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded,
                  color: VColors.textSec),
              title: Text('View Artist',
                  style: GoogleFonts.poppins(color: VColors.textPri)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: VColors.textSec),
              title: Text('Share',
                  style: GoogleFonts.poppins(color: VColors.textPri)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      color: VColors.cardLight,
      child: const Icon(Icons.music_note_rounded,
          color: VColors.textMuted, size: 24),
    );
  }
}
