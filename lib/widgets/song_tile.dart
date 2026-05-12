import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../providers/player_provider.dart';
import '../providers/auth_provider.dart';
import '../models/song_model.dart';
import '../screens/player_screen.dart';
import '../providers/playlist_provider.dart';
import '../services/youtube_service.dart';
import 'create_playlist_sheet.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final List<SongModel> songs;

  const SongTile({super.key, required this.song, required this.songs});

  bool get _isYouTube => song.audioUrl != null && YouTubeService.isYouTubeUrl(song.audioUrl);

  @override
  Widget build(BuildContext context) {
    final isPlaying = context.select<PlayerProvider, bool>(
      (p) => p.currentSong?.id == song.id && p.isPlaying,
    );
    final isLiked = context.select<AuthProvider, bool>(
      (p) => p.isLiked(song.id),
    );

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isPlaying
              ? VColors.primary.withValues(alpha: 0.1)
              : VColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPlaying
                ? VColors.primary.withValues(alpha: 0.4)
                : VColors.divider,
          ),
        ),
        child: Row(
          children: [
            // Album Art — shows YouTube badge if applicable
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: song.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: song.imageUrl,
                          width: 52, height: 52,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const _Placeholder(),
                          errorWidget: (_, __, ___) => const _Placeholder(),
                        )
                      : const _Placeholder(),
                ),
                if (isPlaying && !_isYouTube)
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.volume_up_rounded,
                        color: VColors.primary, size: 22),
                  ),
                if (_isYouTube)
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.red, size: 26),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Song info
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
                  Row(
                    children: [
                      if (_isYouTube) ...[
                        const Icon(Icons.smart_display_rounded,
                            color: Colors.red, size: 12),
                        const SizedBox(width: 3),
                      ],
                      Expanded(
                        child: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: VColors.textSec),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Duration (show YT icon for YouTube songs)
            if (_isYouTube)
              const Icon(Icons.open_in_new_rounded,
                  color: VColors.textMuted, size: 16)
            else
              Text(
                song.durationString,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: VColors.textMuted),
              ),
            const SizedBox(width: 4),

            // Like
            IconButton(
              onPressed: () => context.read<AuthProvider>().toggleLike(song.id),
              icon: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isLiked ? VColors.accent : VColors.textMuted,
                size: 20,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),

            // More options
            IconButton(
              onPressed: () => _showOptions(context),
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

  void _onTap(BuildContext context) {
    // Play all songs (including YouTube) directly as audio in just_audio
    context.read<PlayerProvider>().playSong(song, queue: songs);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PlayerScreen(),
    );
  }

  void _showOptions(BuildContext context) {
    final player = context.read<PlayerProvider>();
    final auth   = context.read<AuthProvider>();

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
            // Song header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: song.imageUrl,
                            width: 48, height: 48, fit: BoxFit.cover)
                        : Container(
                            width: 48, height: 48,
                            color: VColors.card,
                            child: const Icon(Icons.music_note_rounded,
                                color: VColors.primary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song.title,
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                                color: VColors.textPri,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        Text(song.artist,
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                                color: VColors.textSec, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: VColors.divider, height: 1),

            // Add to Queue
            ListTile(
              leading: const Icon(Icons.queue_music_rounded, color: VColors.textSec),
              title: Text('Add to Queue', style: GoogleFonts.poppins(color: VColors.textPri)),
              onTap: () {
                player.addToQueue(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Added to queue',
                      style: GoogleFonts.poppins()),
                  backgroundColor: VColors.primary,
                  duration: const Duration(seconds: 2),
                ));
              },
            ),

            ListTile(
              leading: const Icon(Icons.playlist_add_check_rounded,
                  color: VColors.textSec),
              title: Text('Add to Playlist',
                  style: GoogleFonts.poppins(color: VColors.textPri)),
              onTap: () {
                Navigator.pop(context);
                if (auth.isGuest || auth.user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Sign in to add to playlists',
                        style: GoogleFonts.poppins()),
                    backgroundColor: VColors.primary,
                  ));
                  return;
                }
                _showAddToPlaylistDialog(context, auth.user!.uid);
              },
            ),

            ListTile(
              leading: const Icon(Icons.share_outlined,
                  color: VColors.textSec),
              title: Text('Share',
                  style: GoogleFonts.poppins(color: VColors.textPri)),
              onTap: () {
                Navigator.pop(context);
                final shareText = _isYouTube && song.audioUrl != null
                    ? '🎵 Watch "${song.title}" by ${song.artist} on YouTube!\n'
                      'https://youtu.be/${YouTubeService.extractVideoId(song.audioUrl)}'
                    : '🎵 Listen to "${song.title}" by ${song.artist} on Vibelo!\n${song.audioUrl ?? 'No URL available'}';
                Share.share(shareText, subject: 'Check out this song');
              },
            ),

            // Source badge
            ListTile(
              leading: Icon(
                _isYouTube
                    ? Icons.smart_display_rounded
                    : Icons.verified_outlined,
                color: _isYouTube ? Colors.red : VColors.secondary,
              ),
              title: Text(
                _isYouTube ? 'YouTube Video' : 'Royalty-Free Audio',
                style: GoogleFonts.poppins(color: VColors.textPri),
              ),
              subtitle: Text(
                _isYouTube
                    ? 'YouTube Audio Stream'
                    : _sourceLabel(),
                style: GoogleFonts.poppins(
                    color: VColors.textSec, fontSize: 12),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  String _sourceLabel() {
    final id = song.id;
    if (id.startsWith('deezer_'))  return '30s preview via Deezer';
    if (id.startsWith('audius_'))  return 'Full song via Audius';
    if (id.startsWith('saavn_'))   return 'Full song via JioSaavn';
    return 'Creative Commons via Jamendo';
  }

  void _showAddToPlaylistDialog(BuildContext context, String userId) {
    final playlistProvider = context.read<PlaylistProvider>();
    final playlists = playlistProvider.playlists;

    showModalBottomSheet(
      context: context,
      backgroundColor: VColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add to Playlist',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: VColors.textPri)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.add_circle_outline_rounded,
                  color: VColors.primary),
              title: Text('Create New Playlist',
                  style: GoogleFonts.poppins(
                      color: VColors.primary, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx); // Close current sheet
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CreatePlaylistSheet(songToAdd: song),
                );
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            if (playlists.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('No playlists yet. Create one above!',
                    style: GoogleFonts.poppins(color: VColors.textSec)),
              )
            else
              ...playlists.map((p) => ListTile(
                    leading: Text(p['emoji'] ?? '🎵',
                        style: const TextStyle(fontSize: 24)),
                    title: Text(p['name'] ?? 'Playlist',
                        style: GoogleFonts.poppins(color: VColors.textPri)),
                    onTap: () async {
                      await playlistProvider.addSongToPlaylist(p['id'], song);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added to ${p['name']}',
                                style: GoogleFonts.poppins()),
                            backgroundColor: VColors.primary,
                          ),
                        );
                      }
                    },
                  )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, height: 52,
      color: VColors.cardLight,
      child: const Icon(Icons.music_note_rounded,
          color: VColors.textMuted, size: 24),
    );
  }
}
