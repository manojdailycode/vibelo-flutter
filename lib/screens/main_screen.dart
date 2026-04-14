import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/player_provider.dart';
import '../widgets/mini_player.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  // FIX: Use a static flag so it survives hot reload and widget rebuilds
  // within the same app session.
  static bool _popupShownThisSession = false;

  final _screens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Delay to ensure the widget tree is built before showing dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPremiumPopupOnce();
    });
  }

  Future<void> _showPremiumPopupOnce() async {
    // FIX: Check session guard first — avoids async overhead on subsequent
    // navigations that recreate MainScreen (e.g., sign-in flow).
    if (_popupShownThisSession) return;
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      // FIX: Key 'vibelo_premium_popup_v2' — bump key if you ever want
      // to force-show again on next launch for all users.
      final alreadyShown = prefs.getBool('vibelo_premium_popup_v2') ?? false;

      if (alreadyShown || !mounted) {
        _popupShownThisSession = true;
        return;
      }

      // Mark both session and persistent flags BEFORE showing dialog
      // so a force-close during dialog still prevents re-show.
      _popupShownThisSession = true;
      await prefs.setBool('vibelo_premium_popup_v2', true);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: VColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Vibelo Premium',
                  style: GoogleFonts.poppins(
                      color: VColors.textPri, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Text(
            'Premium payments will be added soon via Razorpay.\n\n'
            'Features coming:\n'
            '• Offline downloads\n'
            '• No ads\n'
            '• HD audio quality\n'
            '• Sleep timer\n'
            '• AI recommendations',
            style: GoogleFonts.poppins(
                color: VColors.textSec, fontSize: 14, height: 1.6),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              style: ElevatedButton.styleFrom(
                backgroundColor: VColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Got it!',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      // Silently fail — never crash the app over a popup
      _popupShownThisSession = true;
      debugPrint('Premium popup error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();

    return Scaffold(
      backgroundColor: VColors.bg,
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player.hasSong) const MiniPlayer(),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: VColors.divider, width: 0.5),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              backgroundColor: VColors.surface,
              selectedItemColor: VColors.primary,
              unselectedItemColor: VColors.textMuted,
              selectedLabelStyle: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  activeIcon: Icon(Icons.search_rounded),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music_outlined),
                  activeIcon: Icon(Icons.library_music_rounded),
                  label: 'Library',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
