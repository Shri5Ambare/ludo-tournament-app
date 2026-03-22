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
  ConnectionResult? _connResult;
  bool _checkingConn = false;

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
    final err = await svc.signInAnonymously(name);
    setState(() => _loading = false);
    if (err == null && mounted) {
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

  Future<void> _testConnection() async {
    setState(() { _checkingConn = true; _connResult = null; });
    final svc = ref.read(supabaseServiceProvider);
    final res = await svc.testConnection();
    if (mounted) {
       setState(() { _checkingConn = false; _connResult = res; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('ONLINE PLAY',
            style: GoogleFonts.fredoka(color: AppColors.textDark, fontSize: 22, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Icon / Hero Section
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: const Text('🌐', style: TextStyle(fontSize: 64))
                  .animate().scale(curve: Curves.elasticOut, duration: 800.ms),
            ),
            const SizedBox(height: 24),
            Text('Connect & Play',
                style: GoogleFonts.fredoka(fontSize: 32, color: AppColors.textDark, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Join the global Ludo community',
                style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textDark.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),

            // Diagnostic Check
            GestureDetector(
              onTap: _checkingConn ? null : _testConnection,
              child: AnimatedContainer(
                duration: 300.ms,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _connResult == null 
                      ? Colors.white.withValues(alpha: 0.1) 
                      : (_connResult!.success ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _connResult == null 
                        ? AppColors.primary.withValues(alpha: 0.2) 
                        : (_connResult!.success ? AppColors.success : AppColors.error),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_checkingConn)
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    else
                      Icon(
                        _connResult == null 
                            ? Icons.wifi_protected_setup_rounded 
                            : (_connResult!.success ? Icons.check_circle_rounded : Icons.error_rounded),
                        size: 16,
                        color: _connResult == null ? AppColors.primary : (_connResult!.success ? AppColors.success : AppColors.error),
                      ),
                    const SizedBox(width: 10),
                    Text(
                      _connResult == null ? 'CHECK CONNECTION' : _connResult!.message.toUpperCase(),
                      style: GoogleFonts.fredoka(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: _connResult == null ? AppColors.primary : (_connResult!.success ? AppColors.success : AppColors.error),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_connResult != null && !_connResult!.success)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _connResult!.details ?? 'Verify your API keys in SETUP.md',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(fontSize: 11, color: AppColors.error.withValues(alpha: 0.7), fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 32),

            // Error
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.error.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_error!,
                          style: GoogleFonts.fredoka(
                              fontSize: 14, color: AppColors.error, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ).animate().shake(),

            // Tab bar
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TabBar(
                controller: _tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7B85FF)]),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textDark.withValues(alpha: 0.4),
                unselectedLabelStyle: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: '👤 GUEST'),
                  Tab(text: '🔑 LOGIN'),
                  Tab(text: '📝 SIGN UP'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 320,
              child: TabBarView(
                controller: _tab,
                children: [
                  // Guest
                  Column(children: [
                    _field(_nameCtrl, 'Display Name', Icons.person_outline_rounded),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.info.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Guest accounts are temporary and tied to this device.',
                                style: GoogleFonts.nunito(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _submitBtn('🎮 PLAY AS GUEST', _guestSignIn),
                  ]),
                  // Login
                  Column(children: [
                    _field(_emailCtrl, 'Email Address', Icons.email_outlined,
                        keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _field(_passCtrl, 'Password', Icons.lock_outline_rounded, obscure: true),
                    const Spacer(),
                    _submitBtn('🔑 SIGN IN', _emailSignIn),
                  ]),
                  // Sign up
                  Column(children: [
                    _field(_nameCtrl, 'Full Name', Icons.person_outline_rounded),
                    const SizedBox(height: 12),
                    _field(_emailCtrl, 'Email Address', Icons.email_outlined,
                        keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _field(_passCtrl, 'Create Password', Icons.lock_outline_rounded, obscure: true),
                    const Spacer(),
                    _submitBtn('📝 CREATE ACCOUNT', _emailSignUp),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboard,
        style: GoogleFonts.fredoka(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.fredoka(color: AppColors.textDark.withValues(alpha: 0.2), fontSize: 16, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: AppColors.primary.withValues(alpha: 0.4), size: 22),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _submitBtn(String label, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7B85FF)]),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: _loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
            : Text(label,
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }
}
