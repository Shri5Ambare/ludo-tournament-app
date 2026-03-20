// lib/screens/tournament/tournament_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tournament_model.dart';
import '../../providers/tournament_provider.dart';

class TournamentSetupScreen extends ConsumerStatefulWidget {
  const TournamentSetupScreen({super.key});

  @override
  ConsumerState<TournamentSetupScreen> createState() =>
      _TournamentSetupScreenState();
}

class _TournamentSetupScreenState extends ConsumerState<TournamentSetupScreen> {
  final _nameController = TextEditingController(text: 'My Tournament');
  final List<TextEditingController> _playerControllers = [];
  TournamentType _type = TournamentType.offline;
  String _gameMode = GameMode.classic;
  int _turnTimer = AppConstants.defaultTurnSeconds;

  int get playerCount => _playerControllers.length;

  @override
  void initState() {
    super.initState();
    // Start with 5 players (minimum)
    for (int i = 1; i <= 5; i++) {
      _playerControllers.add(TextEditingController(text: 'Player $i'));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _playerControllers) c.dispose();
    super.dispose();
  }

  void _addPlayer() {
    if (playerCount >= AppConstants.maxTournamentPlayers) return;
    setState(() {
      _playerControllers.add(
          TextEditingController(text: 'Player ${playerCount + 1}'));
    });
  }

  void _removePlayer() {
    if (playerCount <= AppConstants.minTournamentPlayers) return;
    setState(() {
      _playerControllers.removeLast().dispose();
    });
  }

  int get _groupCount => (playerCount / AppConstants.playersPerGroup).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Tournament Setup',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            _infoCard(),
            const SizedBox(height: 20),

            // Tournament name
            _sectionTitle('Tournament Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: GoogleFonts.nunito(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter tournament name...',
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: AppColors.darkCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Player count
            _sectionTitle('Players ($playerCount/${AppConstants.maxTournamentPlayers})'),
            const SizedBox(height: 8),
            _playerCountControl(),
            const SizedBox(height: 12),
            _groupPreview(),
            const SizedBox(height: 16),
            _playersList(),
            const SizedBox(height: 20),

            // Tournament type
            _sectionTitle('Mode'),
            const SizedBox(height: 8),
            _typeSelector(),
            const SizedBox(height: 20),

            // Game settings
            _sectionTitle('Game Mode'),
            const SizedBox(height: 8),
            _gameModeSelector(),
            const SizedBox(height: 20),

            // Timer
            _sectionTitle('Turn Timer'),
            const SizedBox(height: 8),
            _timerSelector(),
            const SizedBox(height: 32),

            // Start button
            _startButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.3), AppColors.primaryDark.withValues(alpha: 0.2)],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tournament Mode',
                    style: GoogleFonts.fredoka(
                        fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                Text('5–16 players • Group stages • Finals bracket\nBots fill empty slots automatically',
                    style: GoogleFonts.nunito(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _sectionTitle(String t) {
    return Text(t,
        style: GoogleFonts.fredoka(
            fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold));
  }

  Widget _playerCountControl() {
    return Row(
      children: [
        _circleBtn(Icons.remove, _removePlayer,
            enabled: playerCount > AppConstants.minTournamentPlayers),
        const SizedBox(width: 16),
        Container(
          width: 60,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.darkCard,
            border: Border.all(color: AppColors.primary),
          ),
          child: Center(
            child: Text('$playerCount',
                style: GoogleFonts.fredoka(
                    fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        _circleBtn(Icons.add, _addPlayer,
            enabled: playerCount < AppConstants.maxTournamentPlayers),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? AppColors.primary.withValues(alpha: 0.2) : AppColors.darkCard,
          border: Border.all(
              color: enabled ? AppColors.primary : AppColors.darkBorder),
        ),
        child: Icon(icon,
            color: enabled ? AppColors.primary : Colors.white24, size: 22),
      ),
    );
  }

  Widget _groupPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.darkCard,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('📊', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70),
                children: [
                  TextSpan(
                    text: '$_groupCount group${_groupCount > 1 ? 's' : ''} ',
                    style: GoogleFonts.fredoka(
                        fontSize: 14, color: AppColors.accent),
                  ),
                  TextSpan(
                    text: 'of ${AppConstants.playersPerGroup} players. ',
                  ),
                  if (playerCount % AppConstants.playersPerGroup != 0)
                    TextSpan(
                      text: '${AppConstants.playersPerGroup - (playerCount % AppConstants.playersPerGroup)} bot(s) will be added to fill last group.',
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: Colors.white38),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playersList() {
    return Column(
      children: List.generate(_playerControllers.length, (i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.darkCard,
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.2),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Text('${i + 1}',
                      style: GoogleFonts.fredoka(
                          fontSize: 13, color: AppColors.primaryLight)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _playerControllers[i],
                  style: GoogleFonts.nunito(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Player ${i + 1}',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(
                'Group ${String.fromCharCode(65 + i ~/ AppConstants.playersPerGroup)}',
                style: GoogleFonts.nunito(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ).animate(delay: (i * 30).ms).slideX(begin: -0.1).fadeIn();
      }),
    );
  }

  Widget _typeSelector() {
    final types = [
      (TournamentType.offline, '📱 Single Device', 'Pass & play'),
      (TournamentType.hotspot, '📡 Hotspot LAN', 'Multiple devices'),
      (TournamentType.online, '🌐 Online', 'Internet required'),
    ];
    return Column(
      children: types.map((t) {
        final sel = _type == t.$1;
        return GestureDetector(
          onTap: () => setState(() => _type = t.$1),
          child: AnimatedContainer(
            duration: 200.ms,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: sel ? AppColors.primary.withValues(alpha: 0.2) : AppColors.darkCard,
              border: Border.all(
                  color: sel ? AppColors.primary : AppColors.darkBorder,
                  width: sel ? 2 : 1),
            ),
            child: Row(
              children: [
                Text(t.$2,
                    style: GoogleFonts.fredoka(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                const Spacer(),
                Text(t.$3,
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: Colors.white54)),
                if (sel) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _gameModeSelector() {
    final modes = [
      (GameMode.classic, '♟️ Classic'),
      (GameMode.quick, '⚡ Quick'),
    ];
    return Row(
      children: modes.map((m) {
        final sel = _gameMode == m.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => _gameMode = m.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: sel ? AppColors.primary : AppColors.darkCard,
                border: Border.all(
                    color: sel ? AppColors.primary : AppColors.darkBorder),
              ),
              child: Text(m.$2,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _timerSelector() {
    final options = [15, 30, 45];
    return Row(
      children: options.map((t) {
        final sel = _turnTimer == t;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => _turnTimer = t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: sel ? AppColors.accent.withValues(alpha: 0.15) : AppColors.darkCard,
                border: Border.all(
                    color: sel ? AppColors.accent : AppColors.darkBorder),
              ),
              child: Text('${t}s',
                  style: GoogleFonts.fredoka(
                      fontSize: 16,
                      color: sel ? AppColors.accent : Colors.white70)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _startButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _startTournament,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: AppColors.primary.withValues(alpha: 0.5),
        ),
        child: Text('🏆 Start Tournament',
            style: GoogleFonts.fredoka(fontSize: 20, color: Colors.white)),
      ),
    ).animate().scale(curve: Curves.elasticOut, delay: 200.ms);
  }

  void _startTournament() {
    final names = _playerControllers
        .map((c) => c.text.trim().isEmpty ? 'Player' : c.text.trim())
        .toList();

    ref.read(tournamentProvider.notifier).createTournament(
      name: _nameController.text.trim().isEmpty ? 'Tournament' : _nameController.text.trim(),
      playerNames: names,
      type: _type,
      gameMode: _gameMode,
      turnTimerSeconds: _turnTimer,
    );

    final tournament = ref.read(tournamentProvider);
    if (tournament != null) {
      context.push('/tournament/bracket', extra: {'id': tournament.id});
    }
  }
}
