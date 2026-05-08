// ─────────────────────────────────────────────────────────────────────────────
//  search_screen.dart
//
//  Changes vs v1.1.0:
//  - Removed JamendoService import entirely
//  - Genres grid sourced from MusicGenres.genres (Indian languages first)
//  - Removed local Timer debounce — debounce now lives in MusicProvider
//  - Search error message displayed when provider.searchError is set
//  - Genre tap now calls provider.search() so results show in same screen
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/music_provider.dart';
import '../widgets/song_tile.dart';
import '../config/music_genres.dart';

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

  void _onChanged(String value) {
    // Debounce now lives in MusicProvider.search() — no local Timer needed
    context.read<MusicProvider>().search(value);
    setState(() {}); // update clear button visibility
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
                  fontSize:   26,
                  fontWeight: FontWeight.w700,
                  color:      VColors.textPri,
                ),
              ),
              const SizedBox(height: 16),

              // Search field
              TextField(
                controller: _ctrl,
                style:      GoogleFonts.poppins(color: VColors.textPri),
                decoration: InputDecoration(
                  hintText: 'Songs, artists, albums...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: VColors.textSec,
                  ),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: VColors.textSec,
                          ),
                          onPressed: () {
                            _ctrl.clear();
                            context.read<MusicProvider>().clearSearch();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: _onChanged,
              ),
              const SizedBox(height: 20),

              // Results or browse
              Expanded(
                child: music.searchQuery != null
                    ? _SearchResults(music: music)
                    : const _BrowseGenres(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Search Results ────────────────────────────────────────────────────────────
class _SearchResults extends StatelessWidget {
  final MusicProvider music;
  const _SearchResults({required this.music});

  @override
  Widget build(BuildContext context) {
    // Loading
    if (music.loadingSearch) {
      return const Center(
        child: CircularProgressIndicator(color: VColors.primary),
      );
    }

    // Error
    if (music.searchError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: VColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              music.searchError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color:    VColors.textSec,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // No results
    if (music.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                color: VColors.textMuted, size: 56),
            const SizedBox(height: 12),
            Text(
              'No results for "${music.searchQuery}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color:    VColors.textSec,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different song, artist or language',
              style: GoogleFonts.poppins(
                color:    VColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Results list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${music.searchResults.length} results',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color:    VColors.textSec,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: music.searchResults.length,
            itemBuilder: (_, i) => SongTile(
              song:  music.searchResults[i],
              songs: music.searchResults,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Browse Genres (shown when search bar is empty) ────────────────────────────
class _BrowseGenres extends StatelessWidget {
  const _BrowseGenres();

  // Color per genre index — cycles through brand colors
  static const _colors = [
    VColors.primary,
    VColors.secondary,
    VColors.accent,
    VColors.amber,
    Color(0xFF48BB78),
    Color(0xFF4A90D9),
    Color(0xFF9F7AEA),
    Color(0xFFED8936),
    VColors.primary,
    VColors.secondary,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Browse Genres',
          style: GoogleFonts.poppins(
            fontSize:   16,
            fontWeight: FontWeight.w600,
            color:      VColors.textPri,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:   2,
              mainAxisSpacing:  12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
            ),
            itemCount: MusicGenres.genres.length,
            itemBuilder: (_, i) {
              final g     = MusicGenres.genres[i];
              final color = _colors[i % _colors.length];
              return GestureDetector(
                onTap: () {
                  // Search for this genre so results appear in same screen
                  context.read<MusicProvider>().search(g['tag'] as String);
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.55)],
                      begin:  Alignment.topLeft,
                      end:    Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right:  -10,
                        bottom: -10,
                        child: Text(
                          g['emoji'] as String,
                          style: const TextStyle(fontSize: 58),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          g['name'] as String,
                          style: GoogleFonts.poppins(
                            fontSize:   16,
                            fontWeight: FontWeight.w700,
                            color:      Colors.white,
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