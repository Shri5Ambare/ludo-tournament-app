// lib/screens/home/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF1A1035), AppColors.darkBg],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryLight, AppColors.primaryDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.6),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎲', style: TextStyle(fontSize: 72)),
                ),
              )
                  .animate()
                  .scale(duration: 800.ms, curve: Curves.elasticOut)
                  .fadeIn(),

              const SizedBox(height: 32),

              // Title
              Text(
                'LUDO',
                style: GoogleFonts.fredoka(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
              )
                  .animate(delay: 300.ms)
                  .slideY(begin: 0.3, duration: 600.ms)
                  .fadeIn(),

              Text(
                'TOURNAMENT',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  color: AppColors.accent,
                  letterSpacing: 6,
                ),
              )
                  .animate(delay: 500.ms)
                  .slideY(begin: 0.3, duration: 600.ms)
                  .fadeIn(),

              const SizedBox(height: 60),

              // Loading indicator
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.darkCard,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  borderRadius: BorderRadius.circular(8),
                  minHeight: 6,
                ),
              )
                  .animate(delay: 800.ms)
                  .fadeIn()
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: 1500.ms,
                    color: AppColors.primaryLight.withOpacity(0.4),
                  ),

              const SizedBox(height: 16),

              Text(
                'Building Tomorrow\'s Games Today',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ).animate(delay: 1000.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
