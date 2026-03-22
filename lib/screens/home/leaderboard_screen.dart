// lib/screens/home/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/supabase_service.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LeaderboardEntry> _globalLeaders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchLeaders();
  }

  Future<void> _fetchLeaders() async {
    final svc = ref.read(supabaseServiceProvider);
    final results = await svc.fetchGlobalLeaderboard();
    if (mounted) {
      setState(() {
        _globalLeaders = results;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: Text('Leaderboard',
            style: GoogleFonts.fredoka(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 24, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textDark.withValues(alpha: 0.4),
          labelStyle: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'GLOBAL'),
            Tab(text: 'WEEKLY'),
            Tab(text: 'FRIENDS'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _LeaderboardList(players: _globalLeaders),
              _LeaderboardList(players: _globalLeaders.take(5).toList()),
              _LeaderboardList(players: _globalLeaders.where((p) => p.wins > 10).toList()),
            ],
          ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<LeaderboardEntry> players;
  const _LeaderboardList({required this.players});

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text('No leaders yet.\nBe the first to claim the throne!',
                style: GoogleFonts.fredoka(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.4), fontSize: 16),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: players.length,
      itemBuilder: (context, i) {
        final p = players[i];
        return _LeaderRow(
          rank: p.rank,
          name: p.username,
          wins: p.wins,
          level: p.level,
          avatar: p.avatarEmoji,
        ).animate(delay: (i * 50).ms).slideY(begin: 0.1, curve: Curves.easeOutBack).fadeIn();
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
    final bool isTop3 = rank <= 3;
    final Color rankColor = isTop3 
        ? (rank == 1 ? AppColors.accent : (rank == 2 ? const Color(0xFFBDBDBD) : const Color(0xFFCD7F32)))
        : Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: isTop3 ? Border.all(color: rankColor.withValues(alpha: 0.3), width: 2) : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: Text(
              _rankDisplay(rank),
              style: GoogleFonts.fredoka(
                  fontSize: isTop3 ? 24 : 16, color: rankColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withValues(alpha: 0.1),
            ),
            child: Center(
                child: Text(avatar, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          // Name + level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.fredoka(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold)),
                Text('Lvl $level',
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Wins
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$wins',
                  style: GoogleFonts.fredoka(
                      fontSize: 20, color: AppColors.primary, fontWeight: FontWeight.bold)),
              Text('WINS',
                  style: GoogleFonts.fredoka(
                      fontSize: 10, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.3), fontWeight: FontWeight.bold)),
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
      default: return '$rank';
    }
  }
}
