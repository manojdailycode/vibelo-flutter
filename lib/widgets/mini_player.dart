import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;
    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PlayerScreen(),
      ),
      child: Container(
        height: 68,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E2D4A), Color(0xFF111827)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Progress bar at top
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: LinearProgressIndicator(
                value: player.progress,
                backgroundColor: VColors.divider,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(VColors.primary),
                minHeight: 2,
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Album art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: song.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: song.imageUrl,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _PlaceholderArt(),
                              errorWidget: (_, __, ___) => _PlaceholderArt(),
                            )
                          : _PlaceholderArt(),
                    ),
                    const SizedBox(width: 12),

                    // Song info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: VColors.textPri,
                            ),
                          ),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: VColors.textSec),
                          ),
                        ],
                      ),
                    ),

                    // Controls
                    IconButton(
                      onPressed: player.skipPrevious,
                      icon: const Icon(Icons.skip_previous_rounded,
                          color: VColors.textSec, size: 22),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    GestureDetector(
                      onTap: player.togglePlayPause,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [VColors.primary, Color(0xFF4A90D9)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: player.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Icon(
                                player.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                    IconButton(
                      onPressed: player.skipNext,
                      icon: const Icon(Icons.skip_next_rounded,
                          color: VColors.textSec, size: 22),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderArt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      color: VColors.card,
      child: const Icon(Icons.music_note_rounded,
          color: VColors.primary, size: 22),
    );
  }
}
