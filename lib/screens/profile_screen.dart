import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
              Text('Profile',
                  style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: VColors.textPri)),
              const SizedBox(height: 28),

              // Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [VColors.primary, VColors.secondary]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: VColors.primary.withValues(alpha: 0.4),
                          blurRadius: 20)],
                    ),
                    child: Center(
                      child: Text(
                        auth.isGuest
                            ? '👤'
                            : (user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : '?'),
                        style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  Container(
                    width: 28, height: 28,
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
              const SizedBox(height: 12),

              Text(
                auth.isGuest ? 'Guest Listener' : (user?.name ?? 'Vibelo User'),
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: VColors.textPri),
              ),
              if (!auth.isGuest)
                Text(user?.email ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: VColors.textSec)),
              const SizedBox(height: 20),

              if (!auth.isPremium) _PremiumCard() else _PremiumActiveBadge(),
              const SizedBox(height: 24),

              if (!auth.isGuest) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Stat(
                        label: 'Liked Songs',
                        value: '${user?.likedSongIds.length ?? 0}'),
                    _StatDivider(),
                    const _Stat(label: 'Playlists', value: '—'),
                    _StatDivider(),
                    _Stat(
                        label: 'Artists Followed',
                        value: '${user?.followedArtists.length ?? 0}'),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              _SettingsSection(
                title: 'Preferences',
                items: [
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
                    value: 'High (320kbps)',
                    onTap: () => _showAudioQualityDialog(context),
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
                    onTap: () => _showInfoDialog(context, 'Privacy Policy',
                        'Vibelo respects your privacy. We collect only the data needed to provide you with the service. Your data is never sold. Music is sourced from Jamendo under Creative Commons license.'),
                  ),
                  _SettingsItem(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    onTap: () => _showInfoDialog(context, 'Terms of Service',
                        'By using Vibelo, you agree to use royalty-free music only. Do not upload copyrighted content. Vibelo is not responsible for content uploaded by users. All music from Jamendo is Creative Commons licensed.'),
                  ),
                  _SettingsItem(
                    icon: Icons.info_outline_rounded,
                    label: 'App Version',
                    value: 'v1.0.0',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.verified_outlined,
                    label: 'Music License',
                    value: 'Creative Commons',
                    onTap: () => _showInfoDialog(context, 'Music License',
                        'All music in Vibelo comes from Jamendo and is licensed under Creative Commons. Artists freely share their music. You can stream, enjoy, and share legally — no copyright issues.'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

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
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                        borderRadius: BorderRadius.circular(14)),
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

  // ── Language Picker — actually saves ────────
  void _showLanguagePicker(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
            _buildLangOption(
              context: context,
              code: 'en',
              label: 'English',
              flag: '🇬🇧',
              auth: auth,
            ),
            const SizedBox(height: 12),
            _buildLangOption(
              context: context,
              code: 'te',
              label: 'Telugu — తెలుగు',
              flag: '🇮🇳',
              auth: auth,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLangOption({
    required BuildContext context,
    required String code,
    required String label,
    required String flag,
    required AuthProvider auth,
  }) {
    final isSelected = (auth.user?.language ?? 'en') == code;
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        if (auth.user == null) return;
        // Save language to Firestore
        final service = AuthService();
        final updated = auth.user!.copyWith(language: code);
        await service.updateUser(updated);
        // Also save locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('language', code);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                code == 'te'
                    ? 'భాష మార్చబడింది ✓'
                    : 'Language changed to English ✓',
                style: GoogleFonts.poppins()),
            backgroundColor: VColors.primary,
          ));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                style:
                    GoogleFonts.poppins(color: VColors.textPri, fontSize: 15)),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: VColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VColors.surface,
        title: Text('Notifications',
            style: GoogleFonts.poppins(
                color: VColors.textPri, fontWeight: FontWeight.w600)),
        content: Text(
          'New song notifications and trending alerts will be added in a future update.',
          style: GoogleFonts.poppins(color: VColors.textSec, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('OK', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAudioQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VColors.surface,
        title: Text('Audio Quality',
            style: GoogleFonts.poppins(
                color: VColors.textPri, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _qualityOption('High (320kbps)', true),
            _qualityOption('Medium (192kbps)', false),
            _qualityOption('Low (128kbps)', false),
            const SizedBox(height: 8),
            Text(
              'Note: Jamendo streams at optimal quality automatically.',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: VColors.textMuted),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('OK', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _qualityOption(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? VColors.primary : VColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.poppins(
                  color: selected ? VColors.textPri : VColors.textSec,
                  fontSize: 14)),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VColors.surface,
        title: Text(title,
            style: GoogleFonts.poppins(
                color: VColors.textPri, fontWeight: FontWeight.w600)),
        content: Text(content,
            style: GoogleFonts.poppins(
                color: VColors.textSec, fontSize: 14, height: 1.6)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('OK', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
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
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Text('Vibelo Premium',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ]),
          const SizedBox(height: 8),
          Text(
              'Offline downloads • No ads • HD audio\nEqualizer • AI recommendations',
              style:
                  GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: VColors.surface,
                  title: Text('Vibelo Premium',
                      style: GoogleFonts.poppins(
                          color: VColors.textPri,
                          fontWeight: FontWeight.w600)),
                  content: Text(
                      'Premium payments will be added soon via Razorpay.\n\nFeatures coming:\n• Offline downloads\n• No ads\n• HD audio quality\n• Sleep timer\n• AI recommendations',
                      style: GoogleFonts.poppins(
                          color: VColors.textSec, fontSize: 14)),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Got it!',
                          style: GoogleFonts.poppins(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('Upgrade — Coming Soon',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF8C00),
                      fontSize: 13)),
            ),
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
              border: Border.all(color: VColors.divider)),
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
  const _SettingsItem(
      {required this.icon,
      required this.label,
      this.value,
      required this.onTap});

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
