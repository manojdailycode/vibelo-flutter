import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../screens/main_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithEmail(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
    if (ok && mounted) _gotoMain();
  }

  Future<void> _loginGoogle() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (ok && mounted) _gotoMain();
  }

  Future<void> _loginGuest() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInAsGuest();
    if (ok && mounted) _gotoMain();
  }

  void _gotoMain() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: VColors.bgGrad),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo + Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [VColors.primary, VColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: VColors.primary.withValues(alpha: 0.4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.graphic_eq_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to Vibelo',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: VColors.textPri,
                        ),
                      ),
                      Text(
                        'Sign in to continue',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: VColors.textSec,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Error banner
                if (auth.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: VColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: VColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: VColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            auth.error!,
                            style: GoogleFonts.poppins(
                              color: VColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(color: VColors.textPri),
                        decoration: const InputDecoration(
                          hintText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined,
                              color: VColors.textSec),
                        ),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Enter valid email'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        style: GoogleFonts.poppins(color: VColors.textPri),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: VColors.textSec),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: VColors.textSec,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'Min 6 chars' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sign In button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [VColors.primary, Color(0xFF4A90D9)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton(
                      onPressed: auth.loading ? null : _loginEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: auth.loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: VColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or continue with',
                        style: GoogleFonts.poppins(
                          color: VColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: VColors.divider)),
                  ],
                ),
                const SizedBox(height: 20),

                // Google button
                _SocialButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                  iconColor: const Color(0xFF4285F4),
                  onTap: auth.loading ? null : _loginGoogle,
                ),
                const SizedBox(height: 12),

                // Guest button
                _SocialButton(
                  label: 'Continue as Guest',
                  icon: Icons.person_outline_rounded,
                  iconColor: VColors.secondary,
                  onTap: auth.loading ? null : _loginGuest,
                ),
                const SizedBox(height: 32),

                // Sign up link
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: GoogleFonts.poppins(
                          color: VColors.textSec,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: GoogleFonts.poppins(
                              color: VColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: VColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: VColors.textPri,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
