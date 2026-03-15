// lib/core/constants/board_paths.dart
import 'package:flutter/material.dart';

/// Defines the complete Ludo board paths for all 4 players.
/// The board is a 15x15 grid. Each cell is identified by (row, col).
/// Main path has 52 cells. Each player has 6 home column cells + center.

class BoardPaths {
  /// Main circular path (52 cells) - defined for Red player starting at index 0
  /// Other players share same path but start at different indices
  static const List<List<int>> mainPath = [
    // Row, Col  (0-indexed on 15x15 grid)
    [6, 1], [6, 2], [6, 3], [6, 4], [6, 5],   // 0-4   Red start area approach
    [5, 6], [4, 6], [3, 6], [2, 6], [1, 6],   // 5-9
    [0, 6], [0, 7], [0, 8],                    // 10-12
    [1, 8], [2, 8], [3, 8], [4, 8], [5, 8],   // 13-17  Green start area approach
    [6, 9], [6, 10], [6, 11], [6, 12], [6, 13], // 18-22
    [6, 14], [7, 14], [8, 14],                 // 23-25
    [8, 13], [8, 12], [8, 11], [8, 10], [8, 9], // 26-30  Yellow start area approach
    [9, 8], [10, 8], [11, 8], [12, 8], [13, 8], // 31-35
    [14, 8], [14, 7], [14, 6],                 // 36-38
    [13, 6], [12, 6], [11, 6], [10, 6], [9, 6], // 39-43  Blue start area approach
    [8, 5], [8, 4], [8, 3], [8, 2], [8, 1],   // 44-48
    [8, 0], [7, 0], [6, 0],                    // 49-51
  ];

  /// Home column paths for each player (6 cells leading to center)
  static const Map<int, List<List<int>>> homeColumns = {
    0: [[7, 1], [7, 2], [7, 3], [7, 4], [7, 5], [7, 6]], // Red
    1: [[1, 7], [2, 7], [3, 7], [4, 7], [5, 7], [6, 7]], // Green
    2: [[7, 13], [7, 12], [7, 11], [7, 10], [7, 9], [7, 8]], // Yellow
    3: [[13, 7], [12, 7], [11, 7], [10, 7], [9, 7], [8, 7]], // Blue
  };

  /// Home base positions (starting yard) for each player
  static const Map<int, List<List<int>>> homeYards = {
    0: [[1, 1], [1, 3], [3, 1], [3, 3]],   // Red - top-left quadrant
    1: [[1, 11], [1, 13], [3, 11], [3, 13]], // Green - top-right quadrant
    2: [[11, 11], [11, 13], [13, 11], [13, 13]], // Yellow - bottom-right quadrant
    3: [[11, 1], [11, 3], [13, 1], [13, 3]], // Blue - bottom-left quadrant
  };

  /// Player colors
  static const List<Color> playerColors = [
    Color(0xFFE53935), // Red
    Color(0xFF43A047), // Green
    Color(0xFFFDD835), // Yellow
    Color(0xFF1E88E5), // Blue
  ];

  static const List<Color> playerColorsDark = [
    Color(0xFFFF5252), // Red light
    Color(0xFF69F0AE), // Green light
    Color(0xFFFFFF00), // Yellow light
    Color(0xFF40C4FF), // Blue light
  ];

  /// Player color names
  static const List<String> playerColorNames = ['Red', 'Green', 'Yellow', 'Blue'];

  /// Safe positions on main path (star squares)
  static const List<int> safePositions = [0, 8, 13, 21, 26, 34, 39, 47];

  /// Each player's start index on the main path
  static const List<int> playerStartIndex = [0, 13, 26, 39];

  /// Each player's home column entry index on main path
  static const List<int> homeEntryIndex = [50, 11, 24, 37];

  /// Center cell
  static const List<int> centerCell = [7, 7];

  /// Get position on main path for a player given their path progress (0-51)
  static List<int> getMainPathCell(int playerIndex, int pathStep) {
    final adjustedStep = (pathStep + playerStartIndex[playerIndex]) % 52;
    return mainPath[adjustedStep];
  }

  /// Get home column cell for a player at given home step (0-5)
  static List<int> getHomeColumnCell(int playerIndex, int homeStep) {
    return homeColumns[playerIndex]![homeStep];
  }

  /// Check if a position is safe
  static bool isSafePosition(int playerIndex, int pathStep) {
    // Home column is always safe
    if (pathStep > 51) return true;
    final absoluteStep = (pathStep + playerStartIndex[playerIndex]) % 52;
    return safePositions.contains(absoluteStep);
  }
}
