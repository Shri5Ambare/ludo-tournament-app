// lib/core/theme/board_themes.dart
//
// Board skin definitions for the Ludo board painter.
// Each theme controls background, cell, safe-cell, yard, and accent colors.

import 'package:flutter/material.dart';

class BoardThemeData {
  final String id;
  final String label;
  final String emoji;
  final Color background;        // board background
  final Color cellColor;         // main path cell
  final Color safeCellColor;     // safe-zone cell
  final Color gridLine;          // cell border lines
  final Color centerBg;          // center triangle area
  final Color yardOverlay;       // home-yard inner overlay
  final List<Color> playerColors; // override player yard/token colors (null = default)
  final bool glowEffect;         // neon glow on safe cells

  const BoardThemeData({
    required this.id,
    required this.label,
    required this.emoji,
    required this.background,
    required this.cellColor,
    required this.safeCellColor,
    required this.gridLine,
    required this.centerBg,
    required this.yardOverlay,
    this.playerColors = const [],
    this.glowEffect = false,
  });
}

class BoardThemes {
  static const String classic  = 'classic';
  static const String neon     = 'neon';
  static const String royal    = 'royal';
  static const String forest   = 'forest';
  static const String diwali   = 'diwali';

  static const List<String> all = [classic, neon, royal, forest, diwali];

  static const Map<String, BoardThemeData> themes = {
    classic: BoardThemeData(
      id: classic,
      label: 'Classic',
      emoji: '🎮',
      background: Color(0xFF1E1245),
      cellColor: Color(0xFF2A1F55),
      safeCellColor: Color(0xFF1A3A2A),
      gridLine: Color(0x14FFFFFF),
      centerBg: Color(0xFF1E1245),
      yardOverlay: Color(0x14FFFFFF),
      glowEffect: false,
    ),

    neon: BoardThemeData(
      id: neon,
      label: 'Neon',
      emoji: '⚡',
      background: Color(0xFF0A0A14),
      cellColor: Color(0xFF111128),
      safeCellColor: Color(0xFF0D2020),
      gridLine: Color(0x2200FFCC),
      centerBg: Color(0xFF0A0A14),
      yardOverlay: Color(0x1800FFCC),
      playerColors: [
        Color(0xFFFF3366), // neon red
        Color(0xFF00FF99), // neon green
        Color(0xFFFFDD00), // neon yellow
        Color(0xFF3399FF), // neon blue
      ],
      glowEffect: true,
    ),

    royal: BoardThemeData(
      id: royal,
      label: 'Royal Gold',
      emoji: '👑',
      background: Color(0xFF1A1000),
      cellColor: Color(0xFF241800),
      safeCellColor: Color(0xFF1A2800),
      gridLine: Color(0x30FFD700),
      centerBg: Color(0xFF1A1000),
      yardOverlay: Color(0x18FFD700),
      playerColors: [
        Color(0xFFCC2200),  // deep crimson
        Color(0xFF006622),  // deep green
        Color(0xFFBB8800),  // gold-yellow
        Color(0xFF003399),  // royal blue
      ],
      glowEffect: false,
    ),

    forest: BoardThemeData(
      id: forest,
      label: 'Forest',
      emoji: '🌿',
      background: Color(0xFF0D1F0D),
      cellColor: Color(0xFF142214),
      safeCellColor: Color(0xFF0A2A18),
      gridLine: Color(0x2044AA44),
      centerBg: Color(0xFF0D1F0D),
      yardOverlay: Color(0x1844AA44),
      playerColors: [
        Color(0xFFCC3300),  // red-orange
        Color(0xFF33AA00),  // bright green
        Color(0xFFCCAA00),  // amber
        Color(0xFF0055AA),  // deep blue
      ],
      glowEffect: false,
    ),

    diwali: BoardThemeData(
      id: diwali,
      label: 'Diwali',
      emoji: '🪔',
      background: Color(0xFF1A0A00),
      cellColor: Color(0xFF2A1400),
      safeCellColor: Color(0xFF1A200A),
      gridLine: Color(0x30FF8800),
      centerBg: Color(0xFF1A0A00),
      yardOverlay: Color(0x18FF8800),
      playerColors: [
        Color(0xFFFF3300),  // deep red
        Color(0xFF00BB44),  // green
        Color(0xFFFFAA00),  // saffron/orange
        Color(0xFF8833FF),  // purple
      ],
      glowEffect: true,
    ),
  };

  static BoardThemeData get(String id) =>
      themes[id] ?? themes[classic]!;
}
