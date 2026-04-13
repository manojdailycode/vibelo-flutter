import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'onboarding_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.5)),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(_textCtrl);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    _navigate();
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    // Check if onboarding was completed
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      _goto(const MainScreen());
    } else if (onboardingDone) {
      _goto(const OnboardingScreen());
    } else {
      _goto(const OnboardingScreen());
    }
  }

  void _goto(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: VColors.bgGrad),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Logo
              AnimatedBuilder(
                animation: _logoCtrl,
                builder: (_, __) => Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: _VibeleLogoPainter(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Animated App Name
              AnimatedBuilder(
                animation: _textCtrl,
                builder: (_, __) => SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        Text(
                          'Vibelo',
                          style: GoogleFonts.poppins(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: VColors.textPri,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Stream. Discover. Vibe.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: VColors.textSec,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Original Vibelo logo — drawn with Flutter, no external assets
class _VibeleLogoPainter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [VColors.primary, VColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: VColors.primary.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.graphic_eq_rounded,
        color: Colors.white,
        size: 54,
      ),
    );
  }
}
