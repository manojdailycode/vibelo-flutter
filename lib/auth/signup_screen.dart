import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../screens/main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signUpWithEmail(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
    if (ok && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (r) => false,
      );
    }
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
              children: [
                const SizedBox(height: 20),
                // Back + Title
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: VColors.textPri),
                    ),
                    Text(
                      'Create Account',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: VColors.textPri,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Error
                if (auth.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: VColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(auth.error!,
                        style: GoogleFonts.poppins(
                            color: VColors.error, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildField(
                        controller: _nameCtrl,
                        hint: 'Full Name',
                        icon: Icons.person_outline,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _emailCtrl,
                        hint: 'Email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Enter valid email'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _passCtrl,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: VColors.textSec,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Min 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _confCtrl,
                        hint: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscure: true,
                        validator: (v) => v != _passCtrl.text
                            ? "Passwords don't match"
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

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
                      onPressed: auth.loading ? null : _signup,
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
                              'Create Account',
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
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: GoogleFonts.poppins(
                          color: VColors.textSec, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Sign In',
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: VColors.textPri),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: VColors.textSec),
        suffixIcon: suffix,
      ),
      validator: validator,
    );
  }
}
