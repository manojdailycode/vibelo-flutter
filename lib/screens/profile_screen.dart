import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
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

              // Header
              Text(
                'Profile',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: VColors.textPri,
                ),
              ),
              const SizedBox(height: 28),

              // ── FIX: Avatar edit icon now opens the edit modal ──
              GestureDetector(
                onTap: auth.isGuest
                    ? null
                    : () => _showEditProfile(context, auth),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // Avatar circle
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
                    // Edit badge
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

              // Premium Card
              if (!auth.isPremium) _PremiumCard() else _PremiumActiveBadge(),
              const SizedBox(height: 24),

              // Stats Row
              if (!auth.isGuest) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Stat(
                        label: 'Liked Songs',
                        value: '${user?.likedSongIds.length ?? 0}'),
                    _StatDivider(),
                    const _Stat(label: 'Playlists', value: '4'),
                    _StatDivider(),
                    _Stat(
                        label: 'Artists Followed',
                        value: '${user?.followedArtists.length ?? 0}'),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Settings Menu
              _SettingsSection(
                title: 'Preferences',
                items: [
                  _SettingsItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profile',
                    onTap: auth.isGuest
                        ? () {}
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
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.audio_file_outlined,
                    label: 'Audio Quality',
                    value: 'High',
                    onTap: () {},
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
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.info_outline_rounded,
                    label: 'App Version',
                    value: 'v1.1.0',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.verified_outlined,
                    label: 'Music License',
                    value: 'Creative Commons',
                    onTap: () {},
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

  // ── FIX: Fully working edit profile sheet ──────────────────────────────
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
                    // Handle
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

                    // Name field
                    Text('Display Name',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: VColors.textSec,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: 'Your name',
                        prefixIcon: const Icon(Icons.person_outline_rounded,
                            color: VColors.textSec, size: 20),
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
                        filled: true,
                        fillColor: VColors.card,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name cannot be empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Photo URL field
                    Text('Profile Photo URL',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: VColors.textSec,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: photoCtrl,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: 'https://example.com/photo.jpg',
                        prefixIcon: const Icon(Icons.image_outlined,
                            color: VColors.textSec, size: 20),
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
                        filled: true,
                        fillColor: VColors.card,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button
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
                                  // Persist to Firestore
                                  await AuthService()
                                      .updateUser(updatedUser);

                                  // Update local auth provider state
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
}

// ── Avatar fallback ──────────────────────────────────
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

// ─────────────────────────────────────────────
class _PremiumCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text(
                'Vibelo Premium',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Offline downloads • No ads • HD audio\nEqualizer • AI recommendations',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Upgrade — ₹99/month',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF8C00),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumActiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: VColors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VColors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: VColors.amber, size: 22),
          const SizedBox(width: 8),
          Text('Premium Active',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: VColors.amber)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
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
