// ─────────────────────────────────────────────────────────────────────────────
//  mini_player.dart  —  Persistent bottom player bar
//
//  Changes vs v1.1.0:
//  - const _PlaceholderArt (was recreated every frame)
//  - Error indicator dot when PlayerProvider.hasError is true
//  - Tapping the error dot clears it (no extra screen needed)
//  - Gesture: swipe up on mini player opens full PlayerScreen
//  - Progress bar color matches VColors.primary consistently
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  void _openFullPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PlayerScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song   = player.currentSong;
    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: ()              => _openFullPlayer(context),
      onVerticalDragEnd: (d) {
        // Swipe up → open full player
        if (d.primaryVelocity != null && d.primaryVelocity! < -200) {
          _openFullPlayer(context);
        }
      },
      child: Container(
        height: 68,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E2D4A), Color(0xFF111827)],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VColors.divider),
          boxShadow: [
            BoxShadow(
              color:  Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Progress bar — sits at very top of mini player
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: LinearProgressIndicator(
                value:           player.progress,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  VColors.primary,
                ),
                minHeight: 2.5,
              ),
            ),

            // Content row
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Album art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: song.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: song.imageUrl,
                              width:    44,
                              height:   44,
                              fit:      BoxFit.cover,
                              placeholder: (_, __) =>
                                  const _PlaceholderArt(),
                              errorWidget: (_, __, ___) =>
                                  const _PlaceholderArt(),
                            )
                          : const _PlaceholderArt(),
                    ),
                    const SizedBox(width: 11),

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
                              fontSize:   13,
                              fontWeight: FontWeight.w600,
                              color:      VColors.textPri,
                            ),
                          ),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color:    VColors.textSec,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Error indicator — small red dot when playback fails
                    if (player.hasError)
                      GestureDetector(
                        onTap: () {
                          player.clearError();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Playback error cleared.',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: VColors.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width:  8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color:  VColors.error,
                            shape:  BoxShape.circle,
                          ),
                        ),
                      ),

                    // Previous
                    _MiniIconButton(
                      icon:  Icons.skip_previous_rounded,
                      size:  22,
                      onTap: player.skipPrevious,
                    ),

                    // Play / Pause
                    GestureDetector(
                      onTap: player.togglePlayPause,
                      child: Container(
                        width:  38,
                        height: 38,
                        decoration: const BoxDecoration(
                          gradient: VColors.primaryGrad,
                          shape:    BoxShape.circle,
                        ),
                        child: player.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(9),
                                child: CircularProgressIndicator(
                                  color:       Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                player.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size:  22,
                              ),
                      ),
                    ),

                    // Next
                    _MiniIconButton(
                      icon:  Icons.skip_next_rounded,
                      size:  22,
                      onTap: player.skipNext,
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

// ── Icon button sized for mini player ─────────────────────────────────────────
class _MiniIconButton extends StatelessWidget {
  final IconData     icon;
  final double       size;
  final VoidCallback onTap;

  const _MiniIconButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed:   onTap,
        icon:        Icon(icon, color: VColors.textSec, size: size),
        padding:     EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      );
}

// ── Placeholder shown while album art loads ───────────────────────────────────
// const so Flutter never recreates this widget between frames
class _PlaceholderArt extends StatelessWidget {
  const _PlaceholderArt();

  @override
  Widget build(BuildContext context) => Container(
        width:  44,
        height: 44,
        color:  VColors.card,
        child:  const Icon(
          Icons.music_note_rounded,
          color: VColors.primary,
          size:  22,
        ),
      );
}