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
  bool _premiumPopupShown = false; // ← Local guard

  final _screens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPremiumPopupOnce();
    });
  }

  Future<void> _showPremiumPopupOnce() async {
    if (_premiumPopupShown) return; // ← First check: local state
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyShown = prefs.getBool('premium_popup_shown') ?? false;
      if (alreadyShown || !mounted) {
        _premiumPopupShown = true;
        return;
      }
      
      _premiumPopupShown = true; // ← Set before showing dialog
      await prefs.setBool('premium_popup_shown', true);
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: VColors.surface,
          title: Text('Vibelo Premium',
              style: GoogleFonts.poppins(
                  color: VColors.textPri, fontWeight: FontWeight.w600)),
          content: Text(
              'Premium payments will be added soon via Razorpay.\n\nFeatures coming:\n• Offline downloads\n• No ads\n• HD audio quality\n• Sleep timer\n• AI recommendations',
              style: GoogleFonts.poppins(color: VColors.textSec, fontSize: 14)),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: VColors.primary,
              ),
              child: Text('Got it!',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Premium popup error: $e');
      _premiumPopupShown = true;
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
          // Mini Player (visible only when a song is playing)
          if (player.hasSong) const MiniPlayer(),

          // Bottom Nav
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
