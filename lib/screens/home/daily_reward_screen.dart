// lib/screens/home/daily_reward_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

class DailyRewardScreen extends StatefulWidget {
  const DailyRewardScreen({super.key});
  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen> {
  int _streak = 0;
  bool _claimed = false;

  final List<Map<String, dynamic>> _rewards = [
    {'day': 1, 'emoji': '🪙', 'label': '50 Coins', 'coins': 50},
    {'day': 2, 'emoji': '🪙', 'label': '75 Coins', 'coins': 75},
    {'day': 3, 'emoji': '⭐', 'label': '100 Coins + XP', 'coins': 100},
    {'day': 4, 'emoji': '🪙', 'label': '125 Coins', 'coins': 125},
    {'day': 5, 'emoji': '🎲', 'label': 'Fire Dice Skin', 'coins': 0},
    {'day': 6, 'emoji': '🪙', 'label': '200 Coins', 'coins': 200},
    {'day': 7, 'emoji': '👑', 'label': '500 Coins + Crown Token', 'coins': 500},
  ];

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaim = prefs.getString('lastClaimDate') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final streakVal = prefs.getInt('loginStreak') ?? 0;
    final alreadyClaimed = lastClaim == today;
    setState(() {
      _streak = streakVal;
      _claimed = alreadyClaimed;
    });
  }

  Future<void> _claimReward() async {
    if (_claimed) return;
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final newStreak = (_streak % 7) + 1;
    await prefs.setString('lastClaimDate', today);
    await prefs.setInt('loginStreak', newStreak);
    setState(() {
      _streak = newStreak;
      _claimed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayReward = _rewards[(_streak % 7)];

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Daily Rewards',
            style: GoogleFonts.fredoka(color: AppColors.textDark, fontSize: 24, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 110, 20, 40),
        child: Column(
          children: [
            // Streak header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(colors: [
                  AppColors.primary,
                  Color(0xFF7B85FF),
                ]),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 56))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(duration: 1000.ms, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), curve: Curves.easeInOut),
                  const SizedBox(height: 12),
                  Text('$_streak Day Streak!',
                      style: GoogleFonts.fredoka(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Text('Log in every day for bigger rewards',
                      style: GoogleFonts.nunito(
                          fontSize: 14, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),

            const SizedBox(height: 32),

            // 7-day grid
            Row(
              children: [
                Text('WEEKLY CHALLENGE',
                    style: GoogleFonts.fredoka(
                        fontSize: 14,
                        color: AppColors.textDark.withValues(alpha: 0.4),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const Spacer(),
                Text('$_streak/7', style: GoogleFonts.fredoka(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: 7,
              itemBuilder: (context, i) {
                final reward = _rewards[i];
                final dayNum = i + 1;
                final isDone = _streak > i;
                final isToday = _streak % 7 == i && !_claimed;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isDone
                        ? AppColors.success.withValues(alpha: 0.1)
                        : isToday
                            ? AppColors.accent.withValues(alpha: 0.1)
                            : Colors.white,
                    border: Border.all(
                      color: isToday
                              ? AppColors.accent
                              : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                       BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          isDone
                              ? '✅'
                              : reward['emoji'] as String,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text('Day $dayNum',
                          style: GoogleFonts.fredoka(
                              fontSize: 12,
                              color: isToday
                                  ? AppColors.accent
                                  : AppColors.textDark.withValues(alpha: 0.5),
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w500)),
                    ],
                  ),
                ).animate(delay: (i * 50).ms).fadeIn().scale();
              },
            ),

            const SizedBox(height: 32),

            // Today's reward
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Container(height: 1, width: 40, color: AppColors.textDark.withValues(alpha: 0.1)),
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 16),
                         child: Text("TODAY'S REWARD",
                            style: GoogleFonts.fredoka(
                                fontSize: 13, color: AppColors.textDark.withValues(alpha: 0.3), fontWeight: FontWeight.bold, letterSpacing: 1)),
                       ),
                       Container(height: 1, width: 40, color: AppColors.textDark.withValues(alpha: 0.1)),
                     ],
                   ),
                  const SizedBox(height: 24),
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(todayReward['emoji'] as String,
                          style: const TextStyle(fontSize: 64))
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .shake(duration: 2000.ms, hz: 2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(todayReward['label'] as String,
                      style: GoogleFonts.fredoka(
                          fontSize: 24, color: AppColors.textDark, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: _claimed 
                          ? null 
                          : const LinearGradient(colors: [AppColors.primary, Color(0xFF7B85FF)]),
                      color: _claimed ? AppColors.lightBg : null,
                      boxShadow: _claimed ? [] : [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _claimed ? null : _claimReward,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(
                          _claimed ? 'ALREADY CLAIMED' : 'CLAIM REWARD',
                          style: GoogleFonts.fredoka(
                              fontSize: 16, color: _claimed ? AppColors.textDark.withValues(alpha: 0.3) : Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}
