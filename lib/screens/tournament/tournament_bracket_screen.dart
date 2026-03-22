// lib/screens/tournament/tournament_bracket_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import 'package:ludo_tournament_app/core/constants/app_constants.dart';
import '../../models/game_models.dart';
import '../../models/tournament_model.dart';
import '../../providers/tournament_provider.dart';

class TournamentBracketScreen extends ConsumerWidget {
  final String tournamentId;
  const TournamentBracketScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = ref.watch(tournamentProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('TOURNAMENT BRACKET',
            style: GoogleFonts.fredoka(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => _ExitTournamentDialog(ref: ref),
            );
          },
        ),
      ),
      body: Stack(
        children: [
           Positioned(
            top: -100, right: -100,
            child: Container(width: 300, height: 300, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), shape: BoxShape.circle)),
          ),
          if (tournament == null)
            const Center(child: CircularProgressIndicator())
          else if (tournament.isComplete)
            _ChampionScreen(champion: tournament.champion!)
          else
            _BracketView(tournament: tournament, ref: ref),
        ],
      ),
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 110, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Round indicator
          Center(
            child: _RoundBadge(
              label: isGroupStage ? 'GROUP STAGE' : 'FINALS BRACKET',
              icon: isGroupStage ? '⚔️' : '🏆',
            ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
          ),
          const SizedBox(height: 32),

          if (isGroupStage) ...[
            ...tournament.groups.asMap().entries.map((e) {
              return _GroupCard(
                group: e.value,
                onPlayGame: () => _launchGroupGame(context, e.value, tournament),
              ).animate(delay: (e.key * 100).ms).slideY(begin: 0.2, curve: Curves.easeOutQuad).fadeIn();
            }),
          ] else ...[
            _FinalsCard(
              players: tournament.roundWinners,
              onPlayFinals: () => _launchFinalsGame(context, tournament),
            ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms).fadeIn(),
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
      'customRules': tournament.customRules,
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
      'customRules': tournament.customRules,
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
    final bool isCompleted = group.isComplete;
    final Color groupColor = isCompleted ? AppColors.greenPlayer : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          // Group header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              color: groupColor.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: BoxDecoration(color: groupColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                   child: Text(group.groupLabel,
                      style: GoogleFonts.fredoka(
                          fontSize: 18, color: groupColor, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                const Spacer(),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.greenPlayer.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.greenPlayer, size: 14),
                        const SizedBox(width: 6),
                        Text('COMPLETED',
                            style: GoogleFonts.fredoka(
                                fontSize: 10, color: AppColors.greenPlayer, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ],
                    ),
                  )
                else
                  Text('PENDING',
                      style: GoogleFonts.fredoka(
                          fontSize: 11, color: AppColors.textDark.withValues(alpha: 0.3), fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),

          // Players list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: group.players.map((p) {
                final isWinner = group.winnerName == p.name;
                return Container(
                   margin: const EdgeInsets.only(bottom: 10),
                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                   decoration: BoxDecoration(
                      color: isWinner ? AppColors.accent.withValues(alpha: 0.15) : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(20),
                      border: isWinner ? Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1.5) : null,
                   ),
                   child: Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(8),
                         decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                         child: Text(p.isBot ? '🤖' : '🎮', style: const TextStyle(fontSize: 18)),
                       ),
                       const SizedBox(width: 16),
                       Text(p.name,
                          style: GoogleFonts.fredoka(
                              fontSize: 16,
                              color: AppColors.textDark,
                              fontWeight: isWinner ? FontWeight.bold : FontWeight.w600)),
                       const Spacer(),
                       if (isWinner)
                          const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 22),
                     ],
                   ),
                );
              }).toList(),
            ),
          ),

          // Play button
          if (!isCompleted)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7B85FF)]),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onPlayGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text('LAUNCH MATCH',
                      style: GoogleFonts.fredoka(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: AppColors.accent.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 15)),
        ],
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2), width: 3),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 64),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.seconds),
          
          const SizedBox(height: 24),
          Text('FINALS BRACKET', style: GoogleFonts.fredoka(
              fontSize: 26, color: AppColors.textDark, fontWeight: FontWeight.bold, letterSpacing: 2)),
          
          const SizedBox(height: 12),
          Text('Group winners qualify for the grand finale!',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(fontSize: 13, color: AppColors.textDark.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
          
          const SizedBox(height: 32),
          ...players.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.lightBg,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                   padding: const EdgeInsets.all(10),
                   decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                   child: Text(p.isBot ? '🤖' : '👑', style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 16),
                Text(p.name,
                    style: GoogleFonts.fredoka(fontSize: 18, color: AppColors.textDark, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.verified_rounded, color: AppColors.primary, size: 24),
              ],
            ),
          )),
          
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFFFFE066)]),
              boxShadow: [
                BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: ElevatedButton(
              onPressed: onPlayFinals,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              ),
              child: Text('PLAY GRAND FINALE',
                  style: GoogleFonts.fredoka(fontSize: 16, color: AppColors.textDark, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
    return Container(
       width: double.infinity,
       height: double.infinity,
       color: Colors.white,
       child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 300, height: 300, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.05), shape: BoxShape.circle)),
              const Text('🎊', style: TextStyle(fontSize: 120))
                  .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).scale(duration: 1200.ms, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), curve: Curves.elasticInOut),
            ],
          ),
          const SizedBox(height: 48),
          Text('TOURNAMENT CHAMPION',
              style: GoogleFonts.fredoka(
                  fontSize: 22, color: AppColors.accent, fontWeight: FontWeight.bold, letterSpacing: 3))
              .animate(delay: 300.ms).fadeIn().scale(curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Text(champion.name,
              style: GoogleFonts.fredoka(
                  fontSize: 56, color: AppColors.textDark, fontWeight: FontWeight.bold))
              .animate(delay: 600.ms).slideY(begin: 0.5, curve: Curves.elasticOut, duration: 800.ms).fadeIn(),
          const SizedBox(height: 16),
          Text('HE CONQUERED THE BOARD! 🏆',
              style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.textDark.withValues(alpha: 0.4), fontWeight: FontWeight.bold, letterSpacing: 1.5))
              .animate(delay: 900.ms).fadeIn(),
          const SizedBox(height: 80),
          Container(
            width: 240,
            height: 64,
             decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7B85FF)]),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              ),
              child: Text('BACK TO HOME',
                  style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ).animate(delay: 1200.ms).fadeIn().slideY(begin: 0.5, duration: 600.ms),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
             child: Text(icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 16),
          Text(label,
              style: GoogleFonts.fredoka(
                  fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      title: Text('QUIT TOURNAMENT?',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(color: AppColors.textDark, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
      content: Text('Your championship progress will be lost forever. Are you sure?',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(color: AppColors.textDark.withValues(alpha: 0.5), fontWeight: FontWeight.bold, fontSize: 13)),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('STAY', style: GoogleFonts.fredoka(color: AppColors.textDark.withValues(alpha: 0.3), fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ref.read(tournamentProvider.notifier).reset();
                  Navigator.pop(context);
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.error,
                   foregroundColor: Colors.white,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   elevation: 0,
                   padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('QUIT', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
