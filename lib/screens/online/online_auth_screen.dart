// lib/screens/online/online_auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/supabase_service.dart';

class OnlineAuthScreen extends ConsumerStatefulWidget {
  const OnlineAuthScreen({super.key});
  @override
  ConsumerState<OnlineAuthScreen> createState() => _OnlineAuthScreenState();
}

class _OnlineAuthScreenState extends ConsumerState<OnlineAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _guestSignIn() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter your display name');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final svc = ref.read(supabaseServiceProvider);
    final ok = await svc.signInAnonymously(name);
    setState(() => _loading = false);
    if (ok && mounted) {
      context.pushReplacement('/online/lobby', extra: {'isHost': true});
    } else {
      setState(() => _error = 'Guest sign-in failed. Try again.');
    }
  }

  Future<void> _emailSignIn() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Fill in all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final svc = ref.read(supabaseServiceProvider);
    final err = await svc.signInWithEmail(email, pass);
    setState(() => _loading = false);
    if (err == null && mounted) {
      context.pushReplacement('/online/lobby', extra: {'isHost': true});
    } else {
      setState(() => _error = err ?? 'Sign-in failed');
    }
  }

  Future<void> _emailSignUp() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Fill in all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final svc = ref.read(supabaseServiceProvider);
    final err = await svc.signUpWithEmail(email, pass, name);
    setState(() => _loading = false);
    if (err == null && mounted) {
      context.pushReplacement('/online/lobby', extra: {'isHost': true});
    } else {
      setState(() => _error = err ?? 'Sign-up failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('🌐 Online Play',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Icon
            const Text('🌐', style: TextStyle(fontSize: 64))
                .animate().scale(curve: Curves.elasticOut),
            const SizedBox(height: 12),
            Text('Play Online',
                style: GoogleFonts.fredoka(fontSize: 28, color: Colors.white)),
            Text('Connect with players worldwide',
                style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 28),

            // Error
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.error.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Text(_error!,
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: AppColors.error)),
              ).animate().shake(),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primary,
                ),
                labelStyle: GoogleFonts.fredoka(fontSize: 13),
                unselectedLabelStyle: GoogleFonts.nunito(fontSize: 12),
                tabs: const [
                  Tab(text: '👤 Guest'),
                  Tab(text: '🔑 Login'),
                  Tab(text: '📝 Sign Up'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 260,
              child: TabBarView(
                controller: _tab,
                children: [
                  // Guest
                  Column(children: [
                    _field(_nameCtrl, 'Display Name', Icons.person_rounded),
                    const SizedBox(height: 12),
                    Text('Guest accounts are temporary and device-only.',
                        style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMuted),
                        textAlign: TextAlign.center),
                    const Spacer(),
                    _submitBtn('🎮 Play as Guest', _guestSignIn),
                  ]),
                  // Login
                  Column(children: [
                    _field(_emailCtrl, 'Email', Icons.email_rounded,
                        keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    _field(_passCtrl, 'Password', Icons.lock_rounded, obscure: true),
                    const Spacer(),
                    _submitBtn('🔑 Sign In', _emailSignIn),
                  ]),
                  // Sign up
                  Column(children: [
                    _field(_nameCtrl, 'Username', Icons.person_rounded),
                    const SizedBox(height: 10),
                    _field(_emailCtrl, 'Email', Icons.email_rounded,
                        keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    _field(_passCtrl, 'Password', Icons.lock_rounded, obscure: true),
                    const Spacer(),
                    _submitBtn('📝 Create Account', _emailSignUp),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      style: GoogleFonts.nunito(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _submitBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label,
                style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}
