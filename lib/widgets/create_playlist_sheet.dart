import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';

class CreatePlaylistSheet extends StatefulWidget {
  final SongModel? songToAdd;

  const CreatePlaylistSheet({super.key, this.songToAdd});

  @override
  State<CreatePlaylistSheet> createState() => _CreatePlaylistSheetState();
}

class _CreatePlaylistSheetState extends State<CreatePlaylistSheet> {
  final _nameCtrl = TextEditingController();
  String _selectedEmoji = '🎵';
  final _emojis = ['🎵', '🎸', '💜', '🌅', '💪', '🌙', '🎯', '🎉', '😌', '⚡'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createPlaylist() async {
    if (!mounted || _nameCtrl.text.trim().isEmpty) return;

    final playlistProvider = context.read<PlaylistProvider>();
    final newPlaylistId = await playlistProvider.createPlaylist(
      _nameCtrl.text.trim(),
      _selectedEmoji,
    );

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context); // Close the sheet

    if (newPlaylistId != null && widget.songToAdd != null) {
      await playlistProvider.addSongToPlaylist(newPlaylistId, widget.songToAdd!);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Added to "${_nameCtrl.text.trim()}"', style: GoogleFonts.poppins()),
          backgroundColor: VColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 24,
      ),
      decoration: const BoxDecoration(
        color: VColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create New Playlist',
              style: GoogleFonts.poppins(
                  color: VColors.textPri,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _emojis.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _selectedEmoji = _emojis[i]),
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: _selectedEmoji == _emojis[i]
                        ? VColors.primary.withValues(alpha: 0.3)
                        : VColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: _selectedEmoji == _emojis[i]
                        ? Border.all(color: VColors.primary, width: 2)
                        : Border.all(color: VColors.divider),
                  ),
                  child: Center(
                    child: Text(_emojis[i], style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            cursorColor: VColors.primary,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'My Awesome Playlist',
              hintStyle: GoogleFonts.poppins(color: VColors.textMuted),
            ),
            onSubmitted: (_) => _createPlaylist(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _createPlaylist,
              child: Text(
                widget.songToAdd == null
                    ? 'Create Playlist'
                    : 'Create & Add Song',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}