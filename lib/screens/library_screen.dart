import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/music_provider.dart';
import '../widgets/song_tile.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Library',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: VColors.textPri,
                    ),
                  ),
                  IconButton(
                    onPressed: _createPlaylist,
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: VColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: VColors.primary, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 40,
              decoration: BoxDecoration(
                color: VColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [VColors.primary, Color(0xFF4A90D9)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
                labelColor: Colors.white,
                unselectedLabelColor: VColors.textSec,
                tabs: const [
                  Tab(text: 'Liked'),
                  Tab(text: 'Playlists'),
                  Tab(text: 'Recent'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _LikedTab(),
                  _PlaylistsTab(),
                  _RecentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createPlaylist() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VColors.surface,
        title: Text('New Playlist',
            style: GoogleFonts.poppins(color: VColors.textPri)),
        content: TextField(
          style: GoogleFonts.poppins(color: VColors.textPri),
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: VColors.textSec)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Create', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _LikedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final music = context.watch<MusicProvider>();

    final liked = music.trending.where((s) => auth.isLiked(s.id)).toList();

    if (auth.isGuest) {
      return const _EmptyState(
        icon: Icons.person_outline_rounded,
        title: 'Sign in to see liked songs',
        subtitle: 'Create an account to save your favorites',
      );
    }

    if (liked.isEmpty) {
      return const _EmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'No liked songs yet',
        subtitle: 'Tap the heart on any song to save it here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: liked.length,
      itemBuilder: (_, i) => SongTile(song: liked[i], songs: liked),
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  final _samplePlaylists = const [
    {'name': 'Morning Vibes', 'count': 12, 'emoji': '🌅'},
    {'name': 'Workout Mix', 'count': 18, 'emoji': '💪'},
    {'name': 'Late Night', 'count': 9, 'emoji': '🌙'},
    {'name': 'Focus Mode', 'count': 15, 'emoji': '🎯'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Offline downloads card (Premium)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.download_done_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Downloads',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('Premium feature — offline listening',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 22),
            ],
          ),
        ),

        // Playlists
        ..._samplePlaylists.map((p) => _PlaylistCard(playlist: p)),
      ],
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Map<String, dynamic> playlist;
  const _PlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: VColors.primaryGrad,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(playlist['emoji'] as String,
                  style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist['name'] as String,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: VColors.textPri,
                      fontSize: 15),
                ),
                Text(
                  '${playlist['count']} songs',
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: VColors.textSec),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert_rounded, color: VColors.textSec),
        ],
      ),
    );
  }
}

class _RecentTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final recent = music.trending.take(10).toList();

    if (recent.isEmpty) {
      return const _EmptyState(
        icon: Icons.history_rounded,
        title: 'No recent plays',
        subtitle: 'Songs you play will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: recent.length,
      itemBuilder: (_, i) => SongTile(song: recent[i], songs: recent),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: VColors.textMuted, size: 60),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.poppins(
                  color: VColors.textPri,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: VColors.textSec, fontSize: 13)),
        ],
      ),
    );
  }
}
