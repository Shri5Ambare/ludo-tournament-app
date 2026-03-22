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
      backgroundColor: AppColors.lightBg,
      body: Stack(
        children: [
          // Decorative background elements
          Positioned(
             top: -100, left: -100,
             child: Container(width: 300, height: 300, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle)),
          ),
          Positioned(
             bottom: -150, right: -50,
             child: Container(width: 400, height: 400, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), shape: BoxShape.circle)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with complex animation
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 120, height: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF7B85FF)]),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🎲', style: TextStyle(fontSize: 60)),
                      ),
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(duration: 1500.ms, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), curve: Curves.elasticInOut)
                    .animate()
                    .fadeIn(duration: 800.ms),

                const SizedBox(height: 48),

                // Title
                Text(
                  'LUDO CLUB',
                  style: GoogleFonts.fredoka(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: 2,
                  ),
                )
                    .animate()
                    .slideY(begin: 0.5, duration: 800.ms, curve: Curves.easeOutBack)
                    .fadeIn(),

                const SizedBox(height: 8),
                Text(
                  'CHAMPIONSHIP EDITION',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(),

                const SizedBox(height: 80),

                // Premium loading indicator
                Column(
                  children: [
                    SizedBox(
                      width: 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: const LinearProgressIndicator(
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 8,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.5)),
                    
                    const SizedBox(height: 20),
                    Text(
                      'Ready to Play?',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        color: AppColors.textDark.withValues(alpha: 0.3),
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate(delay: 800.ms).fadeIn(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
