// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/home/home_screen.dart';
import '../../screens/home/splash_screen.dart';
import '../../screens/home/leaderboard_screen.dart';
import '../../screens/game/game_lobby_screen.dart';
import '../../screens/game/hotspot_lobby_screen.dart';
import '../../screens/game/game_screen.dart';
import '../../screens/game/result_screen.dart';
import '../../screens/tournament/tournament_setup_screen.dart';
import '../../screens/tournament/tournament_bracket_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/hotspot',
        name: 'hotspot',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return HotspotLobbyScreen(isHost: extra?['isHost'] as bool? ?? false);
        },
      ),
      GoRoute(
        path: '/lobby',
        name: 'lobby',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return GameLobbyScreen(config: extra ?? {});
        },
      ),
      GoRoute(
        path: '/game',
        name: 'game',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return GameScreen(config: extra ?? {});
        },
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ResultScreen(results: extra ?? {});
        },
      ),
      GoRoute(
        path: '/tournament/setup',
        name: 'tournament-setup',
        builder: (context, state) => const TournamentSetupScreen(),
      ),
      GoRoute(
        path: '/tournament/bracket',
        name: 'tournament-bracket',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TournamentBracketScreen(tournamentId: extra?['id'] ?? '');
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
