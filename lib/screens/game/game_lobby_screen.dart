import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/board_paths.dart';
import '../../core/theme/app_theme.dart';
import '../../models/game_models.dart';
import '../../providers/settings_provider.dart';

class GameLobbyScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> config;
  const GameLobbyScreen({super.key, required this.config});

  @override
  ConsumerState<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends ConsumerState<GameLobbyScreen> {
  String mode = 'quick';
  int playerCount = 2;
  String selectedDifficulty = AIDifficulty.medium;
  String selectedGameMode = GameMode.classic;
  int turnTimer = AppConstants.defaultTurnSeconds;
  bool _timerLoadedFromSettings = false;
  CustomRules customRules = const CustomRules();

  final List<TextEditingController> nameControllers =
      List.generate(4, (_) => TextEditingController());
  final List<PlayerType> playerTypes = [
    PlayerType.human, PlayerType.ai, PlayerType.ai, PlayerType.ai
  ];

  @override
  void initState() {
    super.initState();
    mode = widget.config['mode'] as String? ?? 'quick';
    nameControllers[0].text = 'Player 1';
    nameControllers[1].text = 'Bot 1';
    nameControllers[2].text = 'Bot 2';
    nameControllers[3].text = 'Bot 3';

    if (mode == 'ai') {
      playerCount = 2;
      playerTypes[1] = PlayerType.ai;
    } else if (mode == 'local') {
      playerTypes[1] = PlayerType.human;
      playerTypes[2] = PlayerType.human;
      nameControllers[1].text = 'Player 2';
      nameControllers[2].text = 'Player 3';
      nameControllers[3].text = 'Player 4';
    }
  }

  @override
  void dispose() {
    for (final c in nameControllers) {
      c.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Load timer from settings once on first build
    if (!_timerLoadedFromSettings) {
      final savedTimer = ref.read(settingsProvider).turnTimerSeconds;
      turnTimer = savedTimer;
      _timerLoadedFromSettings = true;
    }

    final hasAnyBot = List.generate(playerCount, (i) => playerTypes[i])
        .any((t) => t == PlayerType.ai);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Game Setup', style: GoogleFonts.fredoka(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 24, fontWeight: FontWeight.bold)),
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
          // Background accents
          Positioned(
            top: -100, right: -100,
            child: Container(width: 300, height: 300, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle)),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardSection(
                  title: 'Players',
                  child: Column(
                    children: [
                      _playerCountSelector(),
                      const SizedBox(height: 16),
                      _playersList(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildCardSection(
                  title: 'Game Settings',
                  child: Column(
                    children: [
                      _gameModeSelector(),
                      const SizedBox(height: 20),
                      _timerSelector(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildCardSection(
                  title: '🏠 House Rules',
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text('Configure 11 Custom Rules', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      childrenPadding: EdgeInsets.zero,
                      tilePadding: EdgeInsets.zero,
                      children: [
                        _houseRulesSelector(),
                      ],
                    ),
                  ),
                ),
                if (hasAnyBot) ...[
                  const SizedBox(height: 20),
                  _buildCardSection(
                    title: 'AI Difficulty',
                    child: _difficultySelector(),
                  ),
                ],
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
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title,
              style: GoogleFonts.fredoka(
                  fontSize: 18, color: textColor, fontWeight: FontWeight.bold)),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _playerCountSelector() {
    return Row(
      children: List.generate(3, (i) {
        final count = i + 2;
        final selected = playerCount == count;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
            child: GestureDetector(
              onTap: () => setState(() => playerCount = count),
              child: AnimatedContainer(
                duration: 250.ms,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: selected ? AppColors.primary : Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: selected ? [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                  ] : [],
                ),
                child: Center(
                  child: Text('$count Players',
                      style: GoogleFonts.fredoka(
                          fontSize: 14,
                          color: selected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _playersList() {
    return Column(
      children: List.generate(playerCount, (i) {
        final color = BoardPaths.playerColors[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Text(['🔴', '🟢', '🟡', '🔵'][i], style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: nameControllers[i],
                  style: GoogleFonts.nunito(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Enter name',
                    hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.3)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (i > 0)
                GestureDetector(
                  onTap: () => setState(() {
                    playerTypes[i] = playerTypes[i] == PlayerType.human
                        ? PlayerType.ai
                        : PlayerType.human;
                    if (nameControllers[i].text.startsWith('Bot') || nameControllers[i].text.startsWith('Player')) {
                       nameControllers[i].text = playerTypes[i] == PlayerType.ai ? 'Bot $i' : 'Player ${i + 1}';
                    }
                  }),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: playerTypes[i] == PlayerType.ai ? AppColors.primary : Theme.of(context).cardColor,
                      boxShadow: [
                         BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          playerTypes[i] == PlayerType.ai ? Icons.smart_toy_rounded : Icons.person_rounded,
                          size: 14,
                          color: playerTypes[i] == PlayerType.ai ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          playerTypes[i] == PlayerType.ai ? 'BOT' : 'HUMAN',
                          style: GoogleFonts.fredoka(fontSize: 11, fontWeight: FontWeight.bold, color: playerTypes[i] == PlayerType.ai ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ).animate(delay: (i * 50).ms).slideY(begin: 0.1).fadeIn();
      }),
    );
  }

  Widget _gameModeSelector() {
    final modes = [
      ('classic', '♟️ Classic'),
      ('quick', '⚡ Quick'),
      ('master', '🌟 Master'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mode', style: GoogleFonts.fredoka(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textDark, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: modes.map((m) {
            final sel = selectedGameMode == m.$1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => selectedGameMode = m.$1),
                  child: AnimatedContainer(
                    duration: 250.ms,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: sel ? AppColors.accent : Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: sel ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 8)] : [],
                    ),
                    child: Center(
                      child: Text(m.$2, style: GoogleFonts.fredoka(fontSize: 13, color: sel ? AppColors.textDark : Theme.of(context).textTheme.bodyLarge?.color, fontWeight: sel ? FontWeight.bold : FontWeight.w500)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _timerSelector() {
    final options = [15, 30, 45, 60];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Turn Timer', style: GoogleFonts.fredoka(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textDark, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: options.map((t) {
            final sel = turnTimer == t;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => turnTimer = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: sel ? AppColors.info : Theme.of(context).scaffoldBackgroundColor,
                    ),
                    child: Center(
                      child: Text('${t}s',
                          style: GoogleFonts.fredoka(
                              fontSize: 14,
                              color: sel ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _houseRulesSelector() {
    return Column(
      children: [
        _ruleToggle('6 gives another turn', customRules.sixGivesExtraTurn, (v) => setState(() => customRules = customRules.copyWith(sixGivesExtraTurn: v))),
        _ruleToggle('6 brings a coin out', customRules.sixBringsCoinOut, (v) => setState(() => customRules = customRules.copyWith(sixBringsCoinOut: v))),
        _ruleToggle('Show safe cells (stars)', customRules.safeZonesEnabled, (v) => setState(() => customRules = customRules.copyWith(safeZonesEnabled: v))),
        _ruleToggle('3 consecutive 1s cuts one own coin', customRules.tripleOneKillsOwn, (v) => setState(() => customRules = customRules.copyWith(tripleOneKillsOwn: v))),
        _ruleToggle('Skip a turn on 3 consecutive 1s', customRules.tripleOneSkipsTurn, (v) => setState(() => customRules = customRules.copyWith(tripleOneSkipsTurn: v))),
        _ruleToggle('3 consecutive 6s brings a coin out', customRules.tripleSixBringsCoinOut, (v) => setState(() => customRules = customRules.copyWith(tripleSixBringsCoinOut: v))),
        _ruleToggle('3 consecutive 6s forfeits turn', customRules.tripleSixForfeit, (v) => setState(() => customRules = customRules.copyWith(tripleSixForfeit: v))),
        _ruleToggle('Gains another turn on cutting a coin', customRules.cutGrantsExtraTurn, (v) => setState(() => customRules = customRules.copyWith(cutGrantsExtraTurn: v))),
        _ruleToggle('Gains another turn on reaching home', customRules.homeGrantsExtraTurn, (v) => setState(() => customRules = customRules.copyWith(homeGrantsExtraTurn: v))),
        _ruleToggle('Must cut a coin to enter home lane', customRules.mustCutToEnterHomeLane, (v) => setState(() => customRules = customRules.copyWith(mustCutToEnterHomeLane: v))),
        _ruleToggle('Must cut opponent if possible', customRules.mustCutIfCuttable, (v) => setState(() => customRules = customRules.copyWith(mustCutIfCuttable: v))),
      ],
    );
  }

  Widget _ruleToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: GoogleFonts.nunito(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 30, // constrain switch height
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
              activeThumbColor: AppColors.primary,
              thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                 if (states.contains(WidgetState.selected)) return AppColors.primary;
                 return Colors.white;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _difficultySelector() {
    final levels = [
      (AIDifficulty.easy, '😊 Easy', 'Random moves'),
      (AIDifficulty.medium, '🧠 Medium', 'Smart & balanced'),
      (AIDifficulty.hard, '🔥 Hard', 'Strategic & aggressive'),
    ];
    return Row(
      children: levels.map((d) {
        final sel = selectedDifficulty == d.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => selectedDifficulty = d.$1),
              child: AnimatedContainer(
                duration: 250.ms,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: sel ? AppColors.error : AppColors.lightBg,
                  boxShadow: sel ? [BoxShadow(color: AppColors.error.withValues(alpha: 0.3), blurRadius: 8)] : [],
                ),
                child: Column(
                  children: [
                    Text(d.$2.split(' ')[0], style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(d.$2.split(' ')[1], style: GoogleFonts.fredoka(fontSize: 12, color: sel ? Colors.white : AppColors.textDark, fontWeight: FontWeight.bold)),
                  ],
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
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7B85FF)]),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        ),
        child: Text('START GAME',
            style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
    ).animate().scale(delay: 400.ms, curve: Curves.elasticOut);
  }

  void _startGame() {
    // Deduplicate names
    final usedNames = <String>{};
    final configs = List.generate(playerCount, (i) {
      String name = nameControllers[i].text.trim().isEmpty
          ? BoardPaths.playerColorNames[i]
          : nameControllers[i].text.trim();
      // Append suffix if duplicate
      if (usedNames.contains(name)) {
        name = '$name ${i + 1}';
      }
      usedNames.add(name);
      return {
        'name': name,
        'type': playerTypes[i],
        'difficulty': selectedDifficulty,
        'avatar': ['🔴', '🟢', '🟡', '🔵'][i],
      };
    });

    context.push('/game', extra: {
      'playerConfigs': configs,
      'gameMode': selectedGameMode,
      'turnTimerSeconds': turnTimer,
      'customRules': customRules,
    });
  }
}

