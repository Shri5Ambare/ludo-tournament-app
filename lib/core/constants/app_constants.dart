// lib/core/constants/app_constants.dart

class AppConstants {
  // Game Board
  static const int boardSize = 15;
  static const int totalCells = 52;
  static const int homeCells = 6;
  static const int tokensPerPlayer = 4;
  static const int maxPlayers = 4;
  static const int winPosition = 57; // final home position index
  static const int safeZoneInterval = 8;

  // Tournament
  static const int minTournamentPlayers = 5;
  static const int maxTournamentPlayers = 16;
  static const int playersPerGroup = 4;

  // Timers
  static const int defaultTurnSeconds = 30;
  static const int quickTurnSeconds = 15;
  static const int slowTurnSeconds = 45;

  // AI
  static const int aiThinkDelayMs = 800;
  static const int aiMoveDelayMs = 500;

  // Animation Durations
  static const int diceRollDurationMs = 600;
  static const int tokenMoveDurationMs = 200;
  static const int tokenCutDurationMs = 400;
  static const int celebrationDurationMs = 3000;

  // Player Colors
  static const List<String> playerColorNames = [
    'Red',
    'Green',
    'Yellow',
    'Blue',
  ];

  // Safe Positions on main path (0-indexed from Red start)
  static const List<int> safePositions = [0, 8, 13, 21, 26, 34, 39, 47];

  // Starting positions for each player on main path
  static const List<int> playerStartPositions = [0, 13, 26, 39];

  // Home column entry positions
  static const List<int> homeColumnEntries = [50, 11, 24, 37];

  // Asset paths
  static const String diceSound      = 'dice_roll.mp3';
  static const String tokenMoveSound = 'token_move.mp3';
  static const String tokenCutSound  = 'token_cut.mp3';
  static const String tokenHomeSound = 'token_home.mp3';
  static const String winSound       = 'game_win.mp3';
  static const String loseSound      = 'game_lose.mp3';
  static const String buttonTapSound = 'button_tap.mp3';
  static const String bgMusicPath    = 'bg_music.mp3';

  // Hive Box Names
  static const String profilesBox = 'profiles';
  static const String tournamentsBox = 'tournaments';
  static const String settingsBox = 'settings';

  // Settings Keys
  static const String soundEnabledKey = 'soundEnabled';
  static const String musicEnabledKey = 'musicEnabled';
  static const String vibrationEnabledKey = 'vibrationEnabled';
  static const String themeModeKey = 'themeMode';
  static const String boardThemeKey = 'boardTheme';
}

// BoardThemes string constants + full theme data are in:
// lib/core/theme/board_themes.dart

class GameMode {
  static const String classic = 'classic';
  static const String quick = 'quick';
  static const String master = 'master';
  static const String team = 'team';

  static const List<String> all = [classic, quick, master, team];
}

class AIDifficulty {
  static const String easy = 'easy';
  static const String medium = 'medium';
  static const String hard = 'hard';
}
