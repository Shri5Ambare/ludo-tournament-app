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
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Game Setup', style: GoogleFonts.fredoka(color: Colors.white)),
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
            _sectionTitle('Players'),
            const SizedBox(height: 12),
            _playerCountSelector(),
            const SizedBox(height: 20),
            _playersList(),
            const SizedBox(height: 20),
            _sectionTitle('Game Mode'),
            const SizedBox(height: 12),
            _gameModeSelector(),
            const SizedBox(height: 20),
            _sectionTitle('Turn Timer'),
            const SizedBox(height: 12),
            _timerSelector(),
            const SizedBox(height: 20),
            if (hasAnyBot) ...[
              _sectionTitle('AI Difficulty'),
              const SizedBox(height: 12),
              _difficultySelector(),
              const SizedBox(height: 20),
            ],
            const SizedBox(height: 12),
            _startButton(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.fredoka(
            fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold));
  }

  Widget _playerCountSelector() {
    return Row(
      children: List.generate(3, (i) {
        final count = i + 2;
        final selected = playerCount == count;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => setState(() => playerCount = count),
            child: AnimatedContainer(
              duration: 200.ms,
              width: 60,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: selected ? AppColors.primary : AppColors.darkCard,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.darkBorder,
                ),
              ),
              child: Center(
                child: Text('$count',
                    style: GoogleFonts.fredoka(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
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
        final colorName = BoardPaths.playerColorNames[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.darkCard,
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Text(
                    ['🔴', '🟢', '🟡', '🔵'][i],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: nameControllers[i],
                  style: GoogleFonts.nunito(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '$colorName Player',
                    hintStyle: const TextStyle(color: Colors.white38),
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
                    nameControllers[i].text = playerTypes[i] == PlayerType.ai
                        ? 'Bot $i'
                        : 'Player ${i + 1}';
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: playerTypes[i] == PlayerType.ai
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.darkBorder,
                    ),
                    child: Text(
                      playerTypes[i] == PlayerType.ai ? '🤖 Bot' : '👤 Human',
                      style: GoogleFonts.nunito(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ).animate(delay: (i * 50).ms).slideX(begin: -0.2).fadeIn();
      }),
    );
  }

  Widget _gameModeSelector() {
    final modes = [
      ('classic', '♟️ Classic'),
      ('quick', '⚡ Quick'),
      ('master', '🌟 Master'),
    ];
    return Row(
      children: modes.map((m) {
        final sel = selectedGameMode == m.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => selectedGameMode = m.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: sel ? AppColors.primary : AppColors.darkCard,
                border: Border.all(
                  color: sel ? AppColors.primary : AppColors.darkBorder,
                ),
              ),
              child: Text(m.$2,
                  style: GoogleFonts.nunito(
                      fontSize: 13, color: Colors.white,
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
        final sel = turnTimer == t;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => turnTimer = t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: sel ? AppColors.accent.withValues(alpha: 0.2) : AppColors.darkCard,
                border: Border.all(
                  color: sel ? AppColors.accent : AppColors.darkBorder,
                ),
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

  Widget _difficultySelector() {
    final levels = [
      (AIDifficulty.easy, '😊 Easy', 'Bot makes random moves'),
      (AIDifficulty.medium, '🧠 Medium', 'Smart but beatable'),
      (AIDifficulty.hard, '🔥 Hard', 'Aggressive & strategic'),
    ];
    return Column(
      children: levels.map((d) {
        final sel = selectedDifficulty == d.$1;
        return GestureDetector(
          onTap: () => setState(() => selectedDifficulty = d.$1),
          child: AnimatedContainer(
            duration: 200.ms,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: sel ? AppColors.accent.withValues(alpha: 0.15) : AppColors.darkCard,
              border: Border.all(
                color: sel ? AppColors.accent : AppColors.darkBorder,
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(d.$2,
                    style: GoogleFonts.fredoka(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                const Spacer(),
                Text(d.$3,
                    style: GoogleFonts.nunito(
                        fontSize: 11, color: Colors.white54)),
                if (sel) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.accent, size: 16),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _startButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text('🎲 Start Game',
            style: GoogleFonts.fredoka(fontSize: 20, color: Colors.white)),
      ),
    ).animate().scale(delay: 200.ms, curve: Curves.elasticOut);
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
    });
  }
}

