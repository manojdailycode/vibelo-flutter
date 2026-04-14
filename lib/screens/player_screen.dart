import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../providers/player_provider.dart';
import '../providers/auth_provider.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final auth = context.watch<AuthProvider>();
    final song = player.currentSong;
    if (song == null) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A2236), Color(0xFF070B14)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: VColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: VColors.textSec, size: 28),
                        ),
                        Text(
                          'Now Playing',
                          style: GoogleFonts.poppins(
                            color: VColors.textSec,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showQueue(context, player),
                          icon: const Icon(Icons.queue_music_rounded,
                              color: VColors.textSec, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Album Art
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, child) => Transform.scale(
                        scale: player.isPlaying ? _pulseAnim.value : 1.0,
                        child: child,
                      ),
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: VColors.primary.withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: song.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: song.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _AlbumPlaceholder(),
                                  errorWidget: (_, __, ___) =>
                                      _AlbumPlaceholder(),
                                )
                              : _AlbumPlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Song Info + Like
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: VColors.textPri,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: VColors.textSec,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => auth.toggleLike(song.id),
                          icon: Icon(
                            auth.isLiked(song.id)
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: auth.isLiked(song.id)
                                ? VColors.accent
                                : VColors.textSec,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Progress bar
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: player.progress,
                        onChanged: (v) => player.seekToProgress(v),
                        activeColor: VColors.primary,
                        inactiveColor: VColors.divider,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(player.position),
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: VColors.textSec)),
                          Text(_fmt(player.duration),
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: VColors.textSec)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: player.toggleShuffle,
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color: player.isShuffled
                                ? VColors.primary
                                : VColors.textSec,
                            size: 24,
                          ),
                        ),
                        IconButton(
                          onPressed: player.skipPrevious,
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            color: VColors.textPri,
                            size: 36,
                          ),
                        ),
                        // ── FIX: show loading ONLY during initial load/buffering ──
                        GestureDetector(
                          onTap: player.isLoading ? null : player.togglePlayPause,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [VColors.primary, Color(0xFF4A90D9)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      VColors.primary.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: player.isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Icon(
                                    player.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                          ),
                        ),
                        IconButton(
                          onPressed: player.skipNext,
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: VColors.textPri,
                            size: 36,
                          ),
                        ),
                        IconButton(
                          onPressed: player.toggleLoop,
                          icon: Icon(
                            Icons.repeat_rounded,
                            color: player.isLooping
                                ? VColors.primary
                                : VColors.textSec,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Extra controls row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _IconAction(
                          icon: Icons.equalizer_rounded,
                          label: 'Equalizer',
                          onTap: () => _showEqualizer(context),
                        ),
                        _IconAction(
                          icon: Icons.bedtime_outlined,
                          label: player.sleepMinutes > 0
                              ? player.sleepTimeRemaining ?? 'Sleep'
                              : 'Sleep',
                          onTap: () => _showSleepTimer(context, player),
                          active: player.sleepMinutes > 0,
                        ),
                        _IconAction(
                          icon: Icons.playlist_add_rounded,
                          label: 'Add to List',
                          onTap: () {},
                        ),
                        _IconAction(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Royalty-free badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: VColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                VColors.secondary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: VColors.secondary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Royalty-Free Music via Jamendo',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: VColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FIX: Queue now shows album artwork on the left ──────────────────────
  void _showQueue(BuildContext context, PlayerProvider player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: VColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text('Queue',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: VColors.textPri)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: player.queue.length,
              itemBuilder: (_, i) {
                final s = player.queue[i];
                final isCurrent = i == player.queueIndex;
                return ListTile(
                  // ── Album art instead of plain icon ──
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: s.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: s.imageUrl,
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _QueueArtPlaceholder(
                                    active: isCurrent),
                                errorWidget: (_, __, ___) =>
                                    _QueueArtPlaceholder(active: isCurrent),
                              )
                            : _QueueArtPlaceholder(active: isCurrent),
                      ),
                      // Overlay playing indicator on top of art
                      if (isCurrent)
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.volume_up_rounded,
                              color: VColors.primary, size: 20),
                        ),
                    ],
                  ),
                  title: Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        color: isCurrent ? VColors.primary : VColors.textPri,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 14),
                  ),
                  subtitle: Text(
                    s.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        color: VColors.textSec, fontSize: 12),
                  ),
                  onTap: () {
                    player.playSong(s);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEqualizer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _EqualizerSheet(),
    );
  }

  void _showSleepTimer(BuildContext context, PlayerProvider player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SleepTimerSheet(player: player),
    );
  }
}

// ── Queue art placeholder ────────────────────────
class _QueueArtPlaceholder extends StatelessWidget {
  final bool active;
  const _QueueArtPlaceholder({this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: active ? VColors.primary.withValues(alpha: 0.2) : VColors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.music_note_rounded,
          color: active ? VColors.primary : VColors.textMuted, size: 22),
    );
  }
}

// ─── Equalizer Sheet ─────────────────────────
class _EqualizerSheet extends StatefulWidget {
  const _EqualizerSheet();

  @override
  State<_EqualizerSheet> createState() => _EqualizerSheetState();
}

class _EqualizerSheetState extends State<_EqualizerSheet> {
  final _bands = [
    '60Hz','170Hz','310Hz','600Hz','1kHz',
    '3kHz','6kHz','12kHz','14kHz','16kHz'
  ];
  final _values = List<double>.filled(10, 0);

  final _presets = {
    'Flat':   [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Bass':   [6.0, 5.0, 3.0, 1.0, 0.0,-1.0,-1.0,-1.0,-1.0,-1.0],
    'Treble': [-1.0,-1.0,-1.0,-1.0, 1.0, 3.0, 5.0, 6.0, 6.0, 6.0],
    'Pop':    [-1.0, 2.0, 4.0, 4.0, 2.0, 0.0,-1.0,-1.0,-1.0,-1.0],
    'Rock':   [ 4.0, 3.0, 2.0, 0.0,-1.0,-1.0, 2.0, 3.0, 4.0, 4.0],
    'Jazz':   [ 3.0, 2.0, 1.0, 2.0,-1.0,-1.0, 0.0, 1.0, 3.0, 3.0],
  };

  String _selectedPreset = 'Flat';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: VColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Equalizer',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: VColors.textPri)),
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _presets.keys.map((p) {
                final active = _selectedPreset == p;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPreset = p;
                      for (int i = 0; i < 10; i++) {
                        _values[i] = _presets[p]![i];
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: active ? VColors.primary : VColors.card,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(p,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                active ? Colors.white : VColors.textSec)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(10, (i) {
                return Column(
                  children: [
                    Text('${_values[i].toInt()}',
                        style: GoogleFonts.poppins(
                            fontSize: 9, color: VColors.textSec)),
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: _values[i],
                          min: -10,
                          max: 10,
                          onChanged: (v) => setState(() => _values[i] = v),
                          activeColor: VColors.primary,
                          inactiveColor: VColors.divider,
                        ),
                      ),
                    ),
                    Text(_bands[i],
                        style: GoogleFonts.poppins(
                            fontSize: 8, color: VColors.textMuted)),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Sleep Timer Sheet ───────────────────────
class _SleepTimerSheet extends StatelessWidget {
  final PlayerProvider player;
  const _SleepTimerSheet({required this.player});

  @override
  Widget build(BuildContext context) {
    final options = [5, 10, 15, 20, 30, 45, 60, 90];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: VColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Sleep Timer',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: VColors.textPri)),
          if (player.sleepMinutes > 0) ...[
            const SizedBox(height: 8),
            Text('Stops in: ${player.sleepTimeRemaining}',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: VColors.secondary)),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...options.map((m) => GestureDetector(
                    onTap: () {
                      player.setSleepTimer(m);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: player.sleepMinutes == m
                            ? VColors.primary
                            : VColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('$m min',
                          style: GoogleFonts.poppins(
                              color: VColors.textPri,
                              fontWeight: FontWeight.w500)),
                    ),
                  )),
              if (player.sleepMinutes > 0)
                GestureDetector(
                  onTap: () {
                    player.setSleepTimer(0);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: VColors.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Cancel Timer',
                        style: GoogleFonts.poppins(
                            color: VColors.error,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Icon Action Widget ──────────────────────
class _IconAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active
                  ? VColors.primary.withValues(alpha: 0.2)
                  : VColors.card,
              borderRadius: BorderRadius.circular(14),
              border: active
                  ? Border.all(
                      color: VColors.primary.withValues(alpha: 0.5))
                  : null,
            ),
            child: Icon(icon,
                color: active ? VColors.primary : VColors.textSec,
                size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: active ? VColors.primary : VColors.textSec)),
        ],
      ),
    );
  }
}

// ─── Album placeholder ───────────────────────
class _AlbumPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: VColors.card,
      child: const Center(
        child: Icon(Icons.music_note_rounded,
            color: VColors.primary, size: 80),
      ),
    );
  }
}
