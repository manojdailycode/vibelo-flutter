import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: VColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'Profile',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: VColors.textPri,
                ),
              ),
              const SizedBox(height: 28),

              // Avatar — tap to edit
              GestureDetector(
                onTap: auth.isGuest
                    ? null
                    : () => _showEditProfile(context, auth),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [VColors.primary, VColors.secondary],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: VColors.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: user?.photoUrl != null &&
                                user!.photoUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: user.photoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _AvatarFallback(
                                    isGuest: auth.isGuest, name: user.name),
                                errorWidget: (_, __, ___) => _AvatarFallback(
                                    isGuest: auth.isGuest, name: user.name),
                              )
                            : _AvatarFallback(
                                isGuest: auth.isGuest,
                                name: user?.name ?? ''),
                      ),
                    ),
                    if (!auth.isGuest)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: VColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: VColors.bg, width: 2),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 14),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Text(
                auth.isGuest ? 'Guest Listener' : (user?.name ?? 'Vibelo User'),
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: VColors.textPri),
              ),
              if (!auth.isGuest)
                Text(
                  user?.email ?? '',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: VColors.textSec),
                ),
              const SizedBox(height: 20),

              // Stats Row
              if (!auth.isGuest) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: _Stat(
                          label: 'Liked Songs',
                          value: '${user?.likedSongIds.length ?? 0}'),
                    ),
                    _StatDivider(),
                    const Flexible(
                      child: _Stat(label: 'Playlists', value: '4'),
                    ),
                    _StatDivider(),
                    Flexible(
                      child: _Stat(
                          label: 'Artists Followed',
                          value: '${user?.followedArtists.length ?? 0}'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Preferences section
              _SettingsSection(
                title: 'Preferences',
                items: [
                  _SettingsItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profile',
                    onTap: auth.isGuest
                        ? () => _showGuestSnack(context)
                        : () => _showEditProfile(context, auth),
                  ),
                  _SettingsItem(
                    icon: Icons.language_rounded,
                    label: 'Language',
                    value: user?.language == 'te' ? 'Telugu' : 'English',
                    onTap: () => _showLanguagePicker(context, auth),
                  ),
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => _showNotificationsDialog(context),
                  ),
                  _SettingsItem(
                    icon: Icons.audio_file_outlined,
                    label: 'Audio Quality',
                    value: 'High',
                    onTap: () => _showAudioQualityPicker(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _SettingsSection(
                title: 'About',
                items: [
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () => _showInfoDialog(
                      context,
                      title: 'Privacy Policy',
                      content:
                          'Vibelo collects your email and listening data to personalize your experience. '
                          'We use Firebase for authentication and data storage. '
                          'Your data is never sold to third parties. '
                          'You may delete your account at any time by contacting support.\n\n'
                          'Music is streamed from Jamendo under Creative Commons licenses.',
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    onTap: () => _showInfoDialog(
                      context,
                      title: 'Terms of Service',
                      content:
                          'By using Vibelo you agree to:\n\n'
                          '• Use the app for personal, non-commercial listening only.\n'
                          '• Not reproduce, redistribute, or resell any streamed content.\n'
                          '• Comply with Jamendo\'s Creative Commons licensing terms.\n'
                          '• Not attempt to circumvent DRM or download restrictions.\n\n'
                          'Vibelo is provided "as is" without warranty. '
                          'We reserve the right to update these terms at any time.',
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.info_outline_rounded,
                    label: 'App Version',
                    value: 'v1.1.0',
                    onTap: () => _showAboutDialog(context),
                  ),
                  _SettingsItem(
                    icon: Icons.verified_outlined,
                    label: 'Music License',
                    value: 'Creative Commons',
                    onTap: () => _showInfoDialog(
                      context,
                      title: 'Music License',
                      content:
                          'All music in Vibelo is sourced from Jamendo and licensed under '
                          'Creative Commons (CC BY, CC BY-SA, CC BY-NC, or CC BY-NC-SA).\n\n'
                          'This means:\n'
                          '• Free to stream for personal use\n'
                          '• No copyright strikes\n'
                          '• Artists retain their rights\n\n'
                          'Learn more at jamendo.com/legal/licenses',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sign Out / Sign In
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (auth.isLoggedIn) {
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (r) => false,
                        );
                      }
                    } else {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                        (r) => false,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        auth.isLoggedIn ? VColors.error : VColors.primary,
                    side: BorderSide(
                      color: auth.isLoggedIn
                          ? VColors.error.withValues(alpha: 0.5)
                          : VColors.primary.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(auth.isLoggedIn
                      ? Icons.logout_rounded
                      : Icons.login_rounded),
                  label: Text(
                    auth.isLoggedIn ? 'Sign Out' : 'Sign In',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ── Edit profile bottom sheet ────────────────────────────────────────────
  void _showEditProfile(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.name);
    final photoCtrl = TextEditingController(text: user.photoUrl ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: VColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: VColors.divider,
                              borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Edit Profile',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: VColors.textPri),
                    ),
                    const SizedBox(height: 20),

                    // Display Name
                    Text('Display Name',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: VColors.textSec,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameCtrl,
                      style: GoogleFonts.poppins(color: Colors.white),
                      cursorColor: VColors.primary,
                      decoration: InputDecoration(
                        hintText: 'Your name',
                        hintStyle:
                            GoogleFonts.poppins(color: VColors.textMuted),
                        prefixIcon: const Icon(Icons.person_outline_rounded,
                            color: VColors.textSec, size: 20),
                        filled: true,
                        fillColor: VColors.card,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: VColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: VColors.primary, width: 1.5),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name cannot be empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Profile Photo URL
                    Text('Profile Photo URL',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: VColors.textSec,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      'Paste a public image URL (Google Photos, Imgur, etc.)',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: VColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: photoCtrl,
                      style: GoogleFonts.poppins(color: Colors.white),
                      cursorColor: VColors.primary,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: 'https://example.com/photo.jpg',
                        hintStyle:
                            GoogleFonts.poppins(color: VColors.textMuted),
                        prefixIcon: const Icon(Icons.image_outlined,
                            color: VColors.textSec, size: 20),
                        // Copy button
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste_rounded,
                              color: VColors.textSec, size: 18),
                          onPressed: () async {
                            final data =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null) {
                              photoCtrl.text = data!.text!;
                            }
                          },
                        ),
                        filled: true,
                        fillColor: VColors.card,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: VColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: VColors.primary, width: 1.5),
                        ),
                      ),
                    ),

                    // Live preview
                    if (photoCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('Preview: ',
                              style: GoogleFonts.poppins(
                                  color: VColors.textSec, fontSize: 12)),
                          ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: photoCtrl.text,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 40,
                                height: 40,
                                color: VColors.card,
                                child: const Icon(Icons.broken_image_outlined,
                                    color: VColors.error, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => saving = true);
                                final updatedUser = user.copyWith(
                                  name: nameCtrl.text.trim(),
                                  photoUrl: photoCtrl.text.trim().isEmpty
                                      ? null
                                      : photoCtrl.text.trim(),
                                );
                                try {
                                  await AuthService().updateUser(updatedUser);
                                  auth.updateUserLocally(updatedUser);
                                } catch (e) {
                                  debugPrint('Profile save error: $e');
                                }
                                setModalState(() => saving = false);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text('Save Changes',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Notifications dialog ─────────────────────────────────────────────────
  void _showNotificationsDialog(BuildContext context) {
    bool newReleases = true;
    bool recommendations = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: VColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: VColors.divider,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('Notifications',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: VColors.textPri)),
              const SizedBox(height: 20),
              _SwitchTile(
                  icon: Icons.new_releases_outlined,
                  label: 'New Releases',
                  subtitle: 'When new music is added',
                  value: newReleases,
                  onChanged: (v) => setState(() => newReleases = v)),
              _SwitchTile(
                  icon: Icons.recommend_outlined,
                  label: 'Recommendations',
                  subtitle: 'Personalized picks for you',
                  value: recommendations,
                  onChanged: (v) => setState(() => recommendations = v)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: VColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Push notifications will be available in the next update.',
                        style: GoogleFonts.poppins(
                            color: VColors.primary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Audio Quality picker ─────────────────────────────────────────────────
  void _showAudioQualityPicker(BuildContext context) {
    final player = context.read<PlayerProvider>();
    String selected = 'High';
    final options = [
      {'label': 'Low', 'sub': '64 kbps · Saves data', 'icon': Icons.signal_cellular_alt_1_bar},
      {'label': 'Normal', 'sub': '128 kbps · Balanced', 'icon': Icons.signal_cellular_alt_2_bar},
      {'label': 'High', 'sub': '192 kbps · Recommended', 'icon': Icons.signal_cellular_alt},
      {'label': 'Ultra HD', 'sub': '320 kbps · Best quality', 'icon': Icons.signal_cellular_4_bar},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: VColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: VColors.divider,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('Audio Quality',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: VColors.textPri)),
              const SizedBox(height: 16),
              ...options.map((o) {
                final isSelected = selected == o['label'];
                return GestureDetector(
                  onTap: () async {
                    final label = o['label'] as String;
                    setState(() => selected = label);
                    await player.setAudioQualityLabel(label);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? VColors.primary.withValues(alpha: 0.15)
                          : VColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isSelected
                              ? VColors.primary
                              : VColors.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(o['icon'] as IconData,
                            color: isSelected
                                ? VColors.primary
                                : VColors.textSec,
                            size: 22),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o['label'] as String,
                                  style: GoogleFonts.poppins(
                                      color: VColors.textPri,
                                      fontWeight: FontWeight.w600)),
                              Text(o['sub'] as String,
                                  style: GoogleFonts.poppins(
                                      color: VColors.textSec, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: VColors.primary, size: 20),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Generic info dialog ──────────────────────────────────────────────────
  void _showInfoDialog(BuildContext context,
      {required String title, required String content}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.poppins(
                color: VColors.textPri, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Text(content,
              style: GoogleFonts.poppins(
                  color: VColors.textSec, fontSize: 14, height: 1.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: GoogleFonts.poppins(color: VColors.primary)),
          ),
        ],
      ),
    );
  }

  // ── App About dialog ─────────────────────────────────────────────────────
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [VColors.primary, VColors.secondary]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.graphic_eq_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text('Vibelo',
                style: GoogleFonts.poppins(
                    color: VColors.textPri, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _aboutRow('Version', 'v1.1.0 (build 2)'),
            _aboutRow('Framework', 'Flutter 3.32'),
            _aboutRow('Music Source', 'Jamendo API'),
            _aboutRow('Auth', 'Firebase Auth'),
            _aboutRow('Developer', 'Manoj Kumar'),
            _aboutRow('License', 'MIT'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: GoogleFonts.poppins(color: VColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: VColors.textSec, fontSize: 13)),
          Text(value,
              style: GoogleFonts.poppins(
                  color: VColors.textPri,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Language picker ──────────────────────────────────────────────────────
  void _showLanguagePicker(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Language',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: VColors.textPri)),
            const SizedBox(height: 20),
            _LangOption(code: 'en', label: 'English', flag: '🇬🇧', auth: auth),
            const SizedBox(height: 12),
            _LangOption(
                code: 'te',
                label: 'Telugu — తెలుగు',
                flag: '🇮🇳',
                auth: auth),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showGuestSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sign in to edit your profile',
            style: GoogleFonts.poppins()),
        backgroundColor: VColors.primary,
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;
  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: VColors.textSec,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: VColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VColors.divider),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    const Divider(
                        height: 1, color: VColors.divider, indent: 52),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Small helper widgets ──────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: VColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: VColors.textSec, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        color: VColors.textPri,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        color: VColors.textSec, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.all(VColors.primary),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final bool isGuest;
  final String name;
  const _AvatarFallback({required this.isGuest, required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        isGuest ? '👤' : (name.isNotEmpty ? name[0].toUpperCase() : '?'),
        style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Colors.white),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: VColors.textSec, size: 22),
      title: Text(label,
          style: GoogleFonts.poppins(fontSize: 14, color: VColors.textPri)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(value!,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: VColors.textSec)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              color: VColors.textMuted, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: VColors.textPri)),
        Text(label,
            style:
                GoogleFonts.poppins(fontSize: 11, color: VColors.textSec)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: VColors.divider);
}

class _LangOption extends StatelessWidget {
  final String code;
  final String label;
  final String flag;
  final AuthProvider auth;

  const _LangOption({
    required this.code,
    required this.label,
    required this.flag,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = (auth.user?.language ?? 'en') == code;
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? VColors.primary.withValues(alpha: 0.15)
              : VColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? VColors.primary.withValues(alpha: 0.5)
                  : VColors.divider),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.poppins(
                    color: VColors.textPri, fontSize: 15)),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: VColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
