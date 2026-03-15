// lib/screens/tournament/tournament_bracket_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/game_models.dart';
import '../../models/tournament_model.dart';
import '../../providers/tournament_provider.dart';

class TournamentBracketScreen extends ConsumerWidget {
  final String tournamentId;
  const TournamentBracketScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = ref.watch(tournamentProvider);

    if (tournament == null) {
      return const Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(tournament.name,
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => _ExitTournamentDialog(ref: ref),
            );
          },
        ),
      ),
      body: tournament.isComplete
          ? _ChampionScreen(champion: tournament.champion!)
          : _BracketView(tournament: tournament, ref: ref),
    );
  }
}

class _BracketView extends StatelessWidget {
  final TournamentState tournament;
  final WidgetRef ref;
  const _BracketView({required this.tournament, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isGroupStage = tournament.currentRound == 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Round indicator
          _RoundBadge(
            label: isGroupStage ? 'Round 1: Group Stage' : 'Round 2: Finals',
            icon: isGroupStage ? '⚔️' : '🏆',
          ),
          const SizedBox(height: 20),

          if (isGroupStage) ...[
            ...tournament.groups.asMap().entries.map((e) {
              return _GroupCard(
                group: e.value,
                onPlayGame: () => _launchGroupGame(context, e.value, tournament),
              ).animate(delay: (e.key * 100).ms).slideY(begin: 0.2).fadeIn();
            }),
          ] else ...[
            _FinalsCard(
              players: tournament.roundWinners,
              onPlayFinals: () => _launchFinalsGame(context, tournament),
            ).animate().fadeIn(),
          ],
        ],
      ),
    );
  }

  void _launchGroupGame(
      BuildContext context, TournamentGroup group, TournamentState tournament) {
    final configs = group.players.map((p) => {
      'name': p.name,
      'type': p.isBot ? PlayerType.ai : PlayerType.human,
      'difficulty': AIDifficulty.medium,
      'avatar': p.isBot ? '🤖' : '🎮',
    }).toList();

    context.push('/game', extra: {
      'playerConfigs': configs,
      'gameMode': tournament.gameMode,
      'turnTimerSeconds': tournament.turnTimerSeconds,
      'tournamentGroupIndex': group.groupIndex,
    });
  }

  void _launchFinalsGame(BuildContext context, TournamentState tournament) {
    final configs = tournament.roundWinners.map((p) => {
      'name': p.name,
      'type': p.isBot ? PlayerType.ai : PlayerType.human,
      'difficulty': AIDifficulty.medium,
      'avatar': p.isBot ? '🤖' : '🎮',
    }).toList();

    context.push('/game', extra: {
      'playerConfigs': configs,
      'gameMode': tournament.gameMode,
      'turnTimerSeconds': tournament.turnTimerSeconds,
      'isFinals': true,
    });
  }
}

class _GroupCard extends StatelessWidget {
  final TournamentGroup group;
  final VoidCallback onPlayGame;
  const _GroupCard({required this.group, required this.onPlayGame});

  @override
  Widget build(BuildContext context) {
    final Color groupColor = group.isComplete
        ? AppColors.greenPlayer
        : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.darkCard,
        border: Border.all(
            color: groupColor.withOpacity(0.5),
            width: group.isComplete ? 1.5 : 1),
      ),
      child: Column(
        children: [
          // Group header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              color: groupColor.withOpacity(0.15),
            ),
            child: Row(
              children: [
                Text(group.groupLabel,
                    style: GoogleFonts.fredoka(
                        fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (group.isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.greenPlayer.withOpacity(0.2),
                    ),
                    child: Text('✅ Done',
                        style: GoogleFonts.nunito(
                            fontSize: 12, color: AppColors.greenPlayer)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.accent.withOpacity(0.15),
                    ),
                    child: Text('Pending',
                        style: GoogleFonts.nunito(
                            fontSize: 12, color: AppColors.accent)),
                  ),
              ],
            ),
          ),

          // Players list
          ...group.players.map((p) => ListTile(
                dense: true,
                leading: Text(p.isBot ? '🤖' : '🎮',
                    style: const TextStyle(fontSize: 20)),
                title: Text(p.name,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: group.winnerName == p.name
                            ? AppColors.accent
                            : Colors.white)),
                trailing: group.winnerName == p.name
                    ? const Text('🏆 Winner',
                        style: TextStyle(color: AppColors.accent, fontSize: 12))
                    : null,
              )),

          // Play button
          if (!group.isComplete)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPlayGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('▶ Play ${group.groupLabel} Game',
                      style: GoogleFonts.fredoka(fontSize: 15, color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FinalsCard extends StatelessWidget {
  final List<TournamentPlayer> players;
  final VoidCallback onPlayFinals;
  const _FinalsCard({required this.players, required this.onPlayFinals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacity(0.2),
            AppColors.primary.withOpacity(0.15),
          ],
        ),
        border: Border.all(color: AppColors.accent.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.accent.withOpacity(0.2), blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          Text('🏆 FINALS', style: GoogleFonts.fredoka(
              fontSize: 28, color: AppColors.accent, letterSpacing: 3)),
          const SizedBox(height: 4),
          Text('Group winners compete for the championship',
              style: GoogleFonts.nunito(fontSize: 13, color: Colors.white60)),
          const SizedBox(height: 20),
          ...players.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.darkCard,
            ),
            child: Row(
              children: [
                Text(p.isBot ? '🤖' : '🏆', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(p.name,
                    style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white)),
              ],
            ),
          )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPlayFinals,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('🎲 Play Finals!',
                  style: GoogleFonts.fredoka(fontSize: 18, color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChampionScreen extends StatelessWidget {
  final TournamentPlayer champion;
  const _ChampionScreen({required this.champion});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎊', style: TextStyle(fontSize: 80))
              .animate().scale(curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text('CHAMPION!',
              style: GoogleFonts.fredoka(
                  fontSize: 40, color: AppColors.accent, letterSpacing: 4))
              .animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: 12),
          Text(champion.name,
              style: GoogleFonts.fredoka(
                  fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold))
              .animate(delay: 500.ms).slideY(begin: 0.3).fadeIn(),
          const SizedBox(height: 8),
          Text('Tournament Winner! 🏆',
              style: GoogleFonts.nunito(fontSize: 16, color: Colors.white60))
              .animate(delay: 700.ms).fadeIn(),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('🏠 Back to Home',
                style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white)),
          ).animate(delay: 900.ms).fadeIn(),
        ],
      ),
    );
  }
}

class _RoundBadge extends StatelessWidget {
  final String label;
  final String icon;
  const _RoundBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.darkCard,
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.fredoka(
                  fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ExitTournamentDialog extends StatelessWidget {
  final WidgetRef ref;
  const _ExitTournamentDialog({required this.ref});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Exit Tournament?',
          style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22)),
      content: Text('Tournament progress will be lost.',
          style: GoogleFonts.nunito(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Stay', style: GoogleFonts.nunito(color: AppColors.primary)),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(tournamentProvider.notifier).reset();
            Navigator.pop(context);
            context.go('/home');
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: Text('Exit', style: GoogleFonts.nunito(color: Colors.white)),
        ),
      ],
    );
  }
}
