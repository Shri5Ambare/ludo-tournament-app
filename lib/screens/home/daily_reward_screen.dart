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
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Daily Rewards',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Streak header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(colors: [
                  AppColors.accent.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.15),
                ]),
                border:
                    Border.all(color: AppColors.accent.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 48))
                      .animate()
                      .scale(curve: Curves.elasticOut),
                  const SizedBox(height: 8),
                  Text('$_streak Day Streak!',
                      style: GoogleFonts.fredoka(
                          fontSize: 28,
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold)),
                  Text('Log in every day for bigger rewards',
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: Colors.white60)),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),

            const SizedBox(height: 24),

            // 7-day grid
            Text('This Week',
                style: GoogleFonts.fredoka(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
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
                    borderRadius: BorderRadius.circular(14),
                    color: isDone
                        ? AppColors.greenPlayer.withOpacity(0.1)
                        : isToday
                            ? AppColors.accent.withOpacity(0.15)
                            : AppColors.darkCard,
                    border: Border.all(
                      color: isDone
                          ? AppColors.greenPlayer.withOpacity(0.4)
                          : isToday
                              ? AppColors.accent
                              : AppColors.darkBorder,
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          isDone
                              ? '✅'
                              : reward['emoji'] as String,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text('Day $dayNum',
                          style: GoogleFonts.fredoka(
                              fontSize: 11,
                              color: isToday
                                  ? AppColors.accent
                                  : Colors.white60)),
                    ],
                  ),
                ).animate(delay: (i * 50).ms).fadeIn();
              },
            ),

            const SizedBox(height: 28),

            // Today's reward
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: AppColors.darkCard,
                border: Border.all(
                    color: _claimed
                        ? AppColors.greenPlayer.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Text("Today's Reward",
                      style: GoogleFonts.fredoka(
                          fontSize: 16, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(todayReward['emoji'] as String,
                      style: const TextStyle(fontSize: 52))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                          duration: 1000.ms),
                  const SizedBox(height: 6),
                  Text(todayReward['label'] as String,
                      style: GoogleFonts.fredoka(
                          fontSize: 20, color: AppColors.accent)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _claimed ? null : _claimReward,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _claimed
                            ? AppColors.darkBorder
                            : AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                          _claimed ? '✅ Claimed — Come back tomorrow!' : '🎁 Claim Reward',
                          style: GoogleFonts.fredoka(
                              fontSize: 16, color: Colors.white)),
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
