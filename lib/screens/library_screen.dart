import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/music_provider.dart';
import '../widgets/song_tile.dart';
import '../services/playlist_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _playlistService = PlaylistService();
  List<Map<String, dynamic>> _playlists = [];
  bool _loadingPlaylists = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest || auth.user == null) return;
    setState(() => _loadingPlaylists = true);
    final list = await _playlistService.getPlaylists(auth.user!.uid);
    setState(() {
      _playlists = list;
      _loadingPlaylists = false;
    });
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Library',
                      style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: VColors.textPri)),
                  IconButton(
                    onPressed: _showCreatePlaylistDialog,
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
                      colors: [VColors.primary, Color(0xFF4A90D9)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
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
                  _PlaylistsTab(
                    playlists: _playlists,
                    loading: _loadingPlaylists,
                    onDelete: (id) async {
                      final auth = context.read<AuthProvider>();
                      if (auth.user == null) return;
                      await _playlistService.deletePlaylist(auth.user!.uid, id);
                      _loadPlaylists();
                    },
                  ),
                  _RecentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in to create playlists',
              style: GoogleFonts.poppins()),
          backgroundColor: VColors.primary,
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    String selectedEmoji = '🎵';
    final emojis = ['🎵', '🎸', '💜', '🌅', '💪', '🌙', '🎯', '🎉', '😌', '⚡'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: VColors.surface,
          title: Text('New Playlist',
              style: GoogleFonts.poppins(
                  color: VColors.textPri, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji picker
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: emojis.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setS(() => selectedEmoji = emojis[i]),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: selectedEmoji == emojis[i]
                            ? VColors.primary.withValues(alpha: 0.3)
                            : VColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: selectedEmoji == emojis[i]
                            ? Border.all(color: VColors.primary)
                            : null,
                      ),
                      child: Center(
                        child: Text(emojis[i],
                            style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                cursorColor: VColors.primary,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Playlist name',
                  hintStyle: GoogleFonts.poppins(color: VColors.textMuted),
                  filled: true,
                  fillColor: VColors.card,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: VColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: VColors.primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: VColors.textSec)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final uid = auth.user!.uid;
                await _playlistService.createPlaylist(
                  userId: uid,
                  name: nameCtrl.text.trim(),
                  emoji: selectedEmoji,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _loadPlaylists();
              },
              child: Text('Create',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Liked Tab ────────────────────────────────
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

// ─── Playlists Tab ────────────────────────────
class _PlaylistsTab extends StatelessWidget {
  final List<Map<String, dynamic>> playlists;
  final bool loading;
  final void Function(String id) onDelete;

  const _PlaylistsTab({
    required this.playlists,
    required this.loading,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Downloads premium card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
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
                    Text('Premium — offline listening',
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

        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: VColors.primary),
            ),
          )
        else if (playlists.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: _EmptyState(
              icon: Icons.playlist_add_rounded,
              title: 'No playlists yet',
              subtitle: 'Tap + to create your first playlist',
            ),
          )
        else
          ...playlists.map((p) => _PlaylistCard(
                playlist: p,
                onDelete: () => onDelete(p['id'] as String),
              )),
      ],
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Map<String, dynamic> playlist;
  final VoidCallback onDelete;

  const _PlaylistCard({required this.playlist, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final songs =
        (playlist['songs'] as List?)?.length ?? 0;
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
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: VColors.primaryGrad,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                playlist['emoji'] ?? '🎵',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(playlist['name'] ?? 'Playlist',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: VColors.textPri,
                        fontSize: 15)),
                Text('$songs songs',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: VColors.textSec)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: VColors.surface,
            icon: const Icon(Icons.more_vert_rounded, color: VColors.textSec),
            onSelected: (v) {
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded,
                        color: VColors.error, size: 18),
                    const SizedBox(width: 8),
                    Text('Delete',
                        style: GoogleFonts.poppins(color: VColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Recent Tab ───────────────────────────────
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

// ─── Empty State ──────────────────────────────
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: VColors.textSec, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
