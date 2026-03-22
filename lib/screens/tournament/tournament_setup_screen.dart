// lib/screens/tournament/tournament_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tournament_model.dart';
import '../../models/game_models.dart';
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
  CustomRules _customRules = const CustomRules();

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
    for (final c in _playerControllers) {
      c.dispose();
    }
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('TOURNAMENT SETUP',
            style: GoogleFonts.fredoka(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).iconTheme.color),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _startButton(),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50, left: -50,
            child: Container(width: 200, height: 200, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.05), shape: BoxShape.circle)),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoCard(),
                const SizedBox(height: 32),
                
                _buildCardSection(
                  title: 'BASIC INFO',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text('TOURNAMENT NAME', style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark.withValues(alpha: 0.4), letterSpacing: 1)),
                       const SizedBox(height: 12),
                       TextField(
                         controller: _nameController,
                         style: GoogleFonts.fredoka(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16),
                         decoration: InputDecoration(
                           hintText: 'Enter name...',
                           filled: true,
                           fillColor: AppColors.lightBg,
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                           contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                         ),
                       ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildCardSection(
                  title: 'PARTICIPANTS',
                  child: Column(
                    children: [
                      _playerCountControl(),
                      const SizedBox(height: 24),
                      _groupPreview(),
                      const SizedBox(height: 24),
                      _playersList(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildCardSection(
                  title: 'TOURNAMENT MODE',
                  child: _typeSelector(),
                ),
                const SizedBox(height: 24),

                _buildCardSection(
                  title: 'GAME SETTINGS',
                  child: Column(
                    children: [
                      _gameModeSelector(),
                      const SizedBox(height: 24),
                       Align(
                        alignment: Alignment.centerLeft,
                        child: Text('TURN TIMER', style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark.withValues(alpha: 0.4), letterSpacing: 1)),
                      ),
                      const SizedBox(height: 12),
                      _timerSelector(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const SizedBox(height: 24),
                _buildCardSection(
                  title: 'HOUSE RULES',
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text('Configure 11 Custom Rules', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      childrenPadding: EdgeInsets.zero,
                      tilePadding: EdgeInsets.zero,
                      children: [
                        _buildHouseRules(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({required String title, required Widget child}) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(title,
              style: GoogleFonts.fredoka(
                  fontSize: 13, color: textColor.withValues(alpha: 0.4), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6)),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF7B85FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: const Text('🏆', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHAMPIONSHIP',
                    style: GoogleFonts.fredoka(
                        fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text('5–16 players • Multiple Groups • Final Bracket',
                    style: GoogleFonts.fredoka(fontSize: 11, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 100.ms, curve: Curves.easeOutBack);
  }

  Widget _playerCountControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleBtn(Icons.remove, _removePlayer,
            enabled: playerCount > AppConstants.minTournamentPlayers),
        const SizedBox(width: 32),
        Column(
          children: [
            Text('$playerCount',
                style: GoogleFonts.fredoka(
                    fontSize: 48, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
            Text('PARTICIPANTS', style: GoogleFonts.fredoka(fontSize: 10, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.4), fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
        const SizedBox(width: 32),
        _circleBtn(Icons.add, _addPlayer,
            enabled: playerCount < AppConstants.maxTournamentPlayers),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? AppColors.primary.withValues(alpha: 0.1) : Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(color: enabled ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent),
        ),
        child: Icon(icon,
            color: enabled ? AppColors.primary : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.2), size: 28),
      ),
    );
  }

  Widget _groupPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.primary.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_mosaic_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.fredoka(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                children: [
                  TextSpan(
                    text: '$_groupCount GROUP${_groupCount > 1 ? 'S' : ''} ',
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5),
                  ),
                  const TextSpan(text: 'ARE SCHEDULED'),
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
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
                  ],
                ),
                child: Center(
                  child: Text('${i + 1}',
                      style: GoogleFonts.fredoka(
                          fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _playerControllers[i],
                  style: GoogleFonts.fredoka(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'PLAYER ${i + 1}',
                    hintStyle: GoogleFonts.fredoka(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.2)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  'GROUP ${String.fromCharCode(65 + i ~/ AppConstants.playersPerGroup)}',
                  style: GoogleFonts.fredoka(fontSize: 10, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.4), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ).animate(delay: (i * 30).ms).slideX(begin: 0.1).fadeIn();
      }),
    );
  }

  Widget _typeSelector() {
    final types = [
      (TournamentType.offline, '📱 LOCAL DEVICE', 'Pass & play session'),
      (TournamentType.hotspot, '📡 HOTSPOT LAN', 'Play with friends nearby'),
      (TournamentType.online, '🌐 ONLINE LUDO', 'Play across the world'),
    ];
    return Column(
      children: types.map((t) {
        final sel = _type == t.$1;
        return GestureDetector(
          onTap: () => setState(() => _type = t.$1),
          child: AnimatedContainer(
            duration: 250.ms,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: sel ? AppColors.primary : Theme.of(context).scaffoldBackgroundColor,
              boxShadow: sel ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: (sel ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textDark).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Text(t.$2.split(' ')[0], style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.$2.substring(t.$2.indexOf(' ')+1),
                          style: GoogleFonts.fredoka(
                              fontSize: 16,
                              color: sel ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                      Text(t.$3.toUpperCase(),
                          style: GoogleFonts.fredoka(
                              fontSize: 9, 
                              color: sel ? Colors.white.withValues(alpha: 0.7) : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.4),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
                if (sel) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _gameModeSelector() {
    final modes = [
      (GameMode.classic, '♟️ CLASSIC'),
      (GameMode.quick, '⚡ QUICK'),
    ];
    return Row(
      children: modes.map((m) {
        final sel = _gameMode == m.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _gameMode = m.$1),
              child: AnimatedContainer(
                duration: 250.ms,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: sel ? AppColors.accent : Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: sel ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
                ),
                child: Center(
                  child: Text(m.$2, style: GoogleFonts.fredoka(fontSize: 14, color: sel ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _timerSelector() {
    final options = [15, 30, 45, 60];
    return Row(
      children: options.map((t) {
        final sel = _turnTimer == t;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _turnTimer = t),
              child: AnimatedContainer(
                duration: 250.ms,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: sel ? AppColors.primary : Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: sel ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
                ),
                child: Center(
                  child: Text('${t}S',
                      style: GoogleFonts.fredoka(
                          fontSize: 14,
                          color: sel ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.4),
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _startButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7B85FF)]),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _startTournament,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text('CREATE TOURNAMENT',
            style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
    ).animate().scale(delay: 500.ms, curve: Curves.elasticOut);
  }

  Widget _buildHouseRules() {
    return Column(
      children: [
        _ruleToggle('6 gives another turn', _customRules.sixGivesExtraTurn, (v) => setState(() => _customRules = _customRules.copyWith(sixGivesExtraTurn: v))),
        _ruleToggle('6 brings a coin out', _customRules.sixBringsCoinOut, (v) => setState(() => _customRules = _customRules.copyWith(sixBringsCoinOut: v))),
        _ruleToggle('Show safe cells (stars)', _customRules.safeZonesEnabled, (v) => setState(() => _customRules = _customRules.copyWith(safeZonesEnabled: v))),
        _ruleToggle('3 consecutive 1s cuts one own coin', _customRules.tripleOneKillsOwn, (v) => setState(() => _customRules = _customRules.copyWith(tripleOneKillsOwn: v))),
        _ruleToggle('Skip a turn on 3 consecutive 1s', _customRules.tripleOneSkipsTurn, (v) => setState(() => _customRules = _customRules.copyWith(tripleOneSkipsTurn: v))),
        _ruleToggle('3 consecutive 6s brings a coin out', _customRules.tripleSixBringsCoinOut, (v) => setState(() => _customRules = _customRules.copyWith(tripleSixBringsCoinOut: v))),
        _ruleToggle('3 consecutive 6s forfeits turn', _customRules.tripleSixForfeit, (v) => setState(() => _customRules = _customRules.copyWith(tripleSixForfeit: v))),
        _ruleToggle('Gains another turn on cutting a coin', _customRules.cutGrantsExtraTurn, (v) => setState(() => _customRules = _customRules.copyWith(cutGrantsExtraTurn: v))),
        _ruleToggle('Gains another turn on reaching home', _customRules.homeGrantsExtraTurn, (v) => setState(() => _customRules = _customRules.copyWith(homeGrantsExtraTurn: v))),
        _ruleToggle('Must cut a coin to enter home lane', _customRules.mustCutToEnterHomeLane, (v) => setState(() => _customRules = _customRules.copyWith(mustCutToEnterHomeLane: v))),
        _ruleToggle('Must cut opponent if possible', _customRules.mustCutIfCuttable, (v) => setState(() => _customRules = _customRules.copyWith(mustCutIfCuttable: v))),
      ],
    );
  }

  Widget _ruleToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title.toUpperCase(), style: GoogleFonts.fredoka(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
          SizedBox(
            height: 30, // constrain switch height
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.2),
              activeThumbColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
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
      customRules: _customRules,
    );

    final tournament = ref.read(tournamentProvider);
    if (tournament != null) {
      context.push('/tournament/bracket', extra: {'id': tournament.id});
    }
  }
}
