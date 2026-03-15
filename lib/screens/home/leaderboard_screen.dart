// lib/screens/home/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data for display
  final List<Map<String, dynamic>> _globalLeaders = [
    {'name': 'DragonSlayer', 'wins': 428, 'level': 45, 'avatar': '🐉'},
    {'name': 'LudoMaster', 'wins': 391, 'level': 42, 'avatar': '👑'},
    {'name': 'StrategyKing', 'wins': 355, 'level': 38, 'avatar': '⚔️'},
    {'name': 'SwiftMover', 'wins': 302, 'level': 33, 'avatar': '⚡'},
    {'name': 'TokenCutter', 'wins': 278, 'level': 29, 'avatar': '✂️'},
    {'name': 'BoardWizard', 'wins': 241, 'level': 25, 'avatar': '🧙'},
    {'name': 'DiceRoller', 'wins': 198, 'level': 21, 'avatar': '🎲'},
    {'name': 'QuickPlayer', 'wins': 165, 'level': 17, 'avatar': '🏃'},
    {'name': 'SafeZonePro', 'wins': 134, 'level': 14, 'avatar': '🛡️'},
    {'name': 'YoungStar', 'wins': 98, 'level': 10, 'avatar': '⭐'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Leaderboard',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelStyle: GoogleFonts.fredoka(fontSize: 14),
          unselectedLabelStyle: GoogleFonts.nunito(fontSize: 13),
          tabs: const [
            Tab(text: '🌐 Global'),
            Tab(text: '📅 Weekly'),
            Tab(text: '🏆 Tournament'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LeaderboardList(players: _globalLeaders),
          _LeaderboardList(
              players: _globalLeaders.reversed.take(7).toList()),
          _LeaderboardList(
              players: _globalLeaders.where((p) => p['wins'] > 200).toList()),
        ],
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  const _LeaderboardList({required this.players});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: players.length,
      itemBuilder: (context, i) {
        final p = players[i];
        final rank = i + 1;
        return _LeaderRow(
          rank: rank,
          name: p['name'] as String,
          wins: p['wins'] as int,
          level: p['level'] as int,
          avatar: p['avatar'] as String,
        ).animate(delay: (i * 50).ms).slideX(begin: 0.2).fadeIn();
      },
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final String name;
  final int wins;
  final int level;
  final String avatar;

  const _LeaderRow({
    required this.rank,
    required this.name,
    required this.wins,
    required this.level,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final rankColors = [
      AppColors.accent,
      const Color(0xFFBDBDBD),
      const Color(0xFFCD7F32),
    ];
    final rankColor = isTop3 ? rankColors[rank - 1] : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isTop3
            ? rankColor.withOpacity(0.08)
            : AppColors.darkCard,
        border: Border.all(
          color: isTop3 ? rankColor.withOpacity(0.4) : AppColors.darkBorder,
          width: isTop3 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: Text(
              _rankDisplay(rank),
              style: GoogleFonts.fredoka(
                  fontSize: isTop3 ? 22 : 16, color: rankColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withOpacity(0.15),
              border: Border.all(color: rankColor.withOpacity(0.4)),
            ),
            child: Center(
                child: Text(avatar, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          // Name + level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.fredoka(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight:
                            isTop3 ? FontWeight.bold : FontWeight.normal)),
                Text('Level $level',
                    style: GoogleFonts.nunito(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          // Wins
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$wins',
                  style: GoogleFonts.fredoka(
                      fontSize: 20, color: isTop3 ? rankColor : Colors.white)),
              Text('wins',
                  style: GoogleFonts.nunito(
                      fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  String _rankDisplay(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#$rank';
    }
  }
}
