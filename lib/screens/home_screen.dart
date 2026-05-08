// ─────────────────────────────────────────────────────────────────────────────
//  home_screen.dart
//
//  Changes vs v1.1.0:
//  - Removed JamendoService import and _api field entirely
//  - All loader callbacks now use MusicProvider methods (JioSaavn-backed)
//  - Genres list sourced from MusicGenres.genres (Indian languages first)
//  - Mood tiles sourced from MusicGenres.moodTiles
//  - _FeaturedBanner uses context.select to avoid full rebuilds
//  - _VerticalShimmer and _HorizontalShimmer are const-safe
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../models/song_model.dart';
import '../widgets/song_tile.dart';
import '../config/music_genres.dart';
import 'player_screen.dart';
import 'songs_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicProvider>().loadHomeData();
    });
  }

  void _openSongsList({
    required String title,
    required Future<List<SongModel>> Function() loader,
    String? emoji,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongsListScreen(
          title:  title,
          loader: loader,
          emoji:  emoji,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final music = context.watch<MusicProvider>();
    final name  = auth.user?.name.split(' ').first ?? 'Listener';

    return Scaffold(
      backgroundColor: VColors.bg,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating:         true,
            backgroundColor:  VColors.bg,
            expandedHeight:   0,
            title: Row(
              children: [
                Container(
                  width:  34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient:     const LinearGradient(
                      colors: [VColors.primary, VColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                    size:  20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Vibelo',
                  style: GoogleFonts.poppins(
                    fontSize:   22,
                    fontWeight: FontWeight.w700,
                    color:      VColors.textPri,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: VColors.textPri,
                ),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Notifications coming soon!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: VColors.primary,
                    duration:        const Duration(seconds: 2),
                    behavior:        SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Body
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // Greeting
                Text(
                  _greeting(name),
                  style: GoogleFonts.poppins(
                    fontSize:   22,
                    fontWeight: FontWeight.w700,
                    color:      VColors.textPri,
                  ),
                ),
                Text(
                  'What do you want to listen to?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color:    VColors.textSec,
                  ),
                ),
                const SizedBox(height: 24),

                // Featured banner
                _FeaturedBanner(),
                const SizedBox(height: 28),

                // Moods
                const _SectionHeader(title: 'Moods & Vibes'),
                const SizedBox(height: 12),
                _MoodGrid(
                  onMoodTap: (mood, emoji) => _openSongsList(
                    title:  mood,
                    emoji:  emoji,
                    loader: () =>
                        context.read<MusicProvider>().getMoodSongs(mood),
                  ),
                ),
                const SizedBox(height: 28),

                // Trending
                _SectionHeader(
                  title: 'Trending Now 🔥',
                  onSeeAll: () => _openSongsList(
                    title:  'Trending Now',
                    emoji:  '🔥',
                    loader: () =>
                        context.read<MusicProvider>().getTrending(limit: 50),
                  ),
                ),
                const SizedBox(height: 12),
                if (music.loadingTrending)
                  _HorizontalShimmer()
                else
                  _HorizontalSongList(songs: music.trending),
                const SizedBox(height: 28),

                // New Releases
                _SectionHeader(
                  title: 'New Releases ✨',
                  onSeeAll: () => _openSongsList(
                    title:  'New Releases',
                    emoji:  '✨',
                    loader: () =>
                        context.read<MusicProvider>().getNewReleases(limit: 50),
                  ),
                ),
                const SizedBox(height: 12),
                if (music.loadingNew)
                  _VerticalShimmer()
                else
                  ...music.newReleases.take(8).map(
                        (s) => SongTile(song: s, songs: music.newReleases),
                      ),
                const SizedBox(height: 28),

                // Genres
                const _SectionHeader(title: 'Browse Genres'),
                const SizedBox(height: 12),
                _GenreGrid(
                  onGenreTap: (tag, name, emoji) => _openSongsList(
                    title:  name,
                    emoji:  emoji,
                    loader: () => context
                        .read<MusicProvider>()
                        .getSongsByGenre(tag, limit: 40),
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(String name) {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning, $name 🌅';
    if (h < 17) return 'Good Afternoon, $name ☀️';
    return 'Good Evening, $name 🌙';
  }
}

// ── Featured Banner ───────────────────────────────────────────────────────────
// Uses context.select to only rebuild when trending list changes —
// not on every MusicProvider notification.
class _FeaturedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final trending = context.select<MusicProvider, List<SongModel>>(
      (m) => m.trending,
    );
    final song = trending.isNotEmpty ? trending.first : null;

    return GestureDetector(
      onTap: song == null
          ? null
          : () {
              context
                  .read<PlayerProvider>()
                  .playSong(song, queue: trending);
              showModalBottomSheet(
                context:          context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const PlayerScreen(),
              );
            },
      child: Container(
        height:     180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient:     song == null ? VColors.primaryGrad : null,
          image: song?.imageUrl.isNotEmpty == true
              ? DecorationImage(
                  image: CachedNetworkImageProvider(song!.imageUrl),
                  fit:   BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.45),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Stack(
          children: [
            // Bottom gradient for text legibility
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                ),
              ),
            ),
            // Text
            Positioned(
              bottom: 16,
              left:   16,
              right:  64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical:   3,
                    ),
                    decoration: BoxDecoration(
                      color:        VColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'FEATURED',
                      style: GoogleFonts.poppins(
                        fontSize:    10,
                        fontWeight:  FontWeight.w700,
                        color:       Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    song?.title ?? 'Top Picks for You',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize:   18,
                      fontWeight: FontWeight.w700,
                      color:      Colors.white,
                    ),
                  ),
                  Text(
                    song?.artist ?? 'Various Artists',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color:    Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            // Play button
            Positioned(
              right:  14,
              bottom: 14,
              child: Container(
                width:  42,
                height: 42,
                decoration: BoxDecoration(
                  color:  VColors.primary,
                  shape:  BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:      VColors.primary.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size:  24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mood Grid ─────────────────────────────────────────────────────────────────
class _MoodGrid extends StatelessWidget {
  final void Function(String mood, String emoji) onMoodTap;
  const _MoodGrid({required this.onMoodTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MusicGenres.moodTiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final m     = MusicGenres.moodTiles[i];
          final color = Color(m['color'] as int);
          return GestureDetector(
            onTap: () => onMoodTap(
              m['label'] as String,
              m['emoji'] as String,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
                  border:       Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Text(
                    m['emoji'] as String,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    m['label'] as String,
                    style: GoogleFonts.poppins(
                      fontSize:   13,
                      fontWeight: FontWeight.w500,
                      color:      color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Horizontal Song List (Trending carousel) ──────────────────────────────────
class _HorizontalSongList extends StatelessWidget {
  final List<SongModel> songs;
  const _HorizontalSongList({required this.songs});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount:       songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final song = songs[i];
          return GestureDetector(
            onTap: () {
              context.read<PlayerProvider>().playSong(song, queue: songs);
              showModalBottomSheet(
                context:          context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const PlayerScreen(),
              );
            },
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: song.imageUrl,
                      width:    140,
                      height:   140,
                      fit:      BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: VColors.card,
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: VColors.textMuted,
                          size:  40,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: VColors.card,
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: VColors.textMuted,
                          size:  40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
          );
        },
      ),
    );
  }
}

// ── Genre Grid ────────────────────────────────────────────────────────────────
class _GenreGrid extends StatelessWidget {
  final void Function(String tag, String name, String emoji) onGenreTap;
  const _GenreGrid({required this.onGenreTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics:    const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   2,
        mainAxisSpacing:  12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.4,
      ),
      itemCount: MusicGenres.genres.length,
      itemBuilder: (_, i) {
        final g = MusicGenres.genres[i];
        return GestureDetector(
          onTap: () => onGenreTap(
            g['tag']   as String,
            g['name']  as String,
            g['emoji'] as String,
          ),
          child: Container(
            decoration: BoxDecoration(
              color:        VColors.card,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: VColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width:  48,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient:     VColors.primaryGrad,
                    borderRadius: BorderRadius.only(
                      topLeft:     Radius.circular(12),
                      bottomLeft:  Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      g['emoji'] as String,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    g['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                      color:      VColors.textPri,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String        title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize:   17,
              fontWeight: FontWeight.w700,
              color:      VColors.textPri,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See all',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color:    VColors.primary,
                ),
              ),
            ),
        ],
      );
}

// ── Shimmer Loaders ───────────────────────────────────────────────────────────
class _HorizontalShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 190,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount:       5,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, __) => Shimmer.fromColors(
            baseColor:      VColors.card,
            highlightColor: VColors.cardLight,
            child: Container(
              width:  140,
              height: 140,
              decoration: BoxDecoration(
                color:        VColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      );
}

class _VerticalShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(
          5,
          (_) => Shimmer.fromColors(
            baseColor:      VColors.card,
            highlightColor: VColors.cardLight,
            child: Container(
              height: 70,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color:        VColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
}