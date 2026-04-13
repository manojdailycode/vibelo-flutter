import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/music_provider.dart';
import '../widgets/song_tile.dart';
import '../services/jamendo_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search(String q) {
    context.read<MusicProvider>().search(q);
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    return Scaffold(
      backgroundColor: VColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Search',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: VColors.textPri,
                ),
              ),
              const SizedBox(height: 16),

              // Search bar
              TextField(
                controller: _ctrl,
                onTap: () => setState(() {}),
                style: GoogleFonts.poppins(color: VColors.textPri),
                decoration: InputDecoration(
                  hintText: 'Artists, songs, albums...',
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: VColors.textSec),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: VColors.textSec),
                          onPressed: () {
                            _ctrl.clear();
                            context.read<MusicProvider>().clearSearch();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (v) {
                  _search(v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),

              Expanded(
                child: music.searchQuery != null
                    ? _SearchResults(music: music)
                    : _BrowseGenres(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final MusicProvider music;
  const _SearchResults({required this.music});

  @override
  Widget build(BuildContext context) {
    if (music.loadingSearch) {
      return const Center(
        child: CircularProgressIndicator(color: VColors.primary),
      );
    }
    if (music.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                color: VColors.textMuted, size: 60),
            const SizedBox(height: 12),
            Text(
              'No results for "${music.searchQuery}"',
              style: GoogleFonts.poppins(color: VColors.textSec, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${music.searchResults.length} results',
          style: GoogleFonts.poppins(fontSize: 13, color: VColors.textSec),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: music.searchResults.length,
            itemBuilder: (_, i) => SongTile(
              song: music.searchResults[i],
              songs: music.searchResults,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrowseGenres extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const genres = JamendoService.genres;
    final colors = [
      VColors.primary,
      VColors.secondary,
      VColors.accent,
      VColors.amber,
      const Color(0xFF48BB78),
      const Color(0xFF4A90D9),
      const Color(0xFF9F7AEA),
      const Color(0xFFED8936),
      VColors.primary,
      VColors.secondary,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Browse Genres',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: VColors.textPri,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
            ),
            itemCount: genres.length,
            itemBuilder: (_, i) {
              final g = genres[i];
              return GestureDetector(
                onTap: () {
                  context.read<MusicProvider>().loadGenre(g['tag'] as String);
                  context.read<MusicProvider>().search(g['tag'] as String);
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors[i % colors.length],
                        colors[i % colors.length].withValues(alpha: 0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: Text(
                          g['emoji'] as String,
                          style: const TextStyle(fontSize: 60),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          g['name'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
