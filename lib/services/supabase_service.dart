// lib/services/supabase_service.dart
//
// Supabase backend service for online multiplayer.
// Tables needed in your Supabase project:
//
//   profiles      (id uuid PK, username text, avatar_emoji text, level int,
//                  wins int, losses int, coins int, xp int, created_at timestamptz)
//
//   online_rooms  (id uuid PK, host_id uuid, room_code text UNIQUE,
//                  game_mode text, turn_timer int, status text,
//                  player_ids uuid[], created_at timestamptz)
//
//   room_players  (id uuid PK, room_id uuid FK, player_id uuid FK,
//                  player_index int, is_ready bool, joined_at timestamptz)
//
//   game_events   (id uuid PK, room_id uuid FK, player_id uuid FK,
//                  event_type text, payload jsonb, created_at timestamptz)
//
//   tournaments   (id uuid PK, name text, host_id uuid, status text,
//                  player_names text[], champion_name text, created_at timestamptz)

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseServiceProvider =
    Provider<SupabaseService>((ref) => SupabaseService());

// ─────────────────────────────────────────────────────────────────────────────
// Stub — replace with real Supabase client once you add supabase_flutter dep
// ─────────────────────────────────────────────────────────────────────────────

/// Supabase project URL — set via environment or .env file
const String kSupabaseUrl = 'https://YOUR_PROJECT.supabase.co';

/// Supabase anon key — safe to include in client apps
const String kSupabaseAnonKey = 'YOUR_ANON_KEY';

class SupabaseService {
  // ── Auth ──────────────────────────────────────────────────────────────────

  bool get isSignedIn => _currentUserId != null;
  String? _currentUserId;
  String? get currentUserId => _currentUserId;
  String? _username;
  String? get username => _username;

  /// Sign in anonymously (guest play) — generates a local UUID
  Future<bool> signInAnonymously(String displayName) async {
    try {
      // In real impl: await Supabase.instance.client.auth.signInAnonymously()
      _currentUserId = _generateUuid();
      _username = displayName;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sign in with email + password
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      // Real: await Supabase.instance.client.auth.signInWithPassword(...)
      _currentUserId = _generateUuid();
      return null; // null = no error
    } catch (e) {
      return e.toString();
    }
  }

  /// Sign up new account
  Future<String?> signUpWithEmail(
      String email, String password, String username) async {
    try {
      _currentUserId = _generateUuid();
      _username = username;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    _currentUserId = null;
    _username = null;
  }

  // ── Rooms ─────────────────────────────────────────────────────────────────

  /// Create an online room, returns room code (e.g. "ABC123")
  Future<OnlineRoom?> createRoom({
    required String gameMode,
    required int turnTimer,
    required int maxPlayers,
  }) async {
    final code = _generateRoomCode();
    final room = OnlineRoom(
      id: _generateUuid(),
      code: code,
      hostId: _currentUserId ?? '',
      hostName: _username ?? 'Host',
      gameMode: gameMode,
      turnTimer: turnTimer,
      maxPlayers: maxPlayers,
      players: [
        RoomPlayer(
          id: _currentUserId ?? '',
          name: _username ?? 'Host',
          index: 0,
          isReady: true,
          isHost: true,
        ),
      ],
      status: RoomStatus.waiting,
    );
    // Real: await supabase.from('online_rooms').insert(room.toJson())
    _activeRoom = room;
    return room;
  }

  /// Join a room by code
  Future<OnlineRoom?> joinRoom(String code) async {
    // Real: supabase.from('online_rooms').select().eq('room_code', code).single()
    if (_activeRoom == null || _activeRoom!.code != code.toUpperCase()) {
      return null; // Room not found
    }
    final room = _activeRoom!;
    if (room.players.length >= room.maxPlayers) return null;

    final newPlayer = RoomPlayer(
      id: _currentUserId ?? _generateUuid(),
      name: _username ?? 'Player',
      index: room.players.length,
      isReady: false,
      isHost: false,
    );
    room.players.add(newPlayer);
    return room;
  }

  /// Set ready status
  Future<void> setReady(String roomId, bool ready) async {
    // Real: supabase.from('room_players').update({'is_ready': ready})...
  }

  OnlineRoom? _activeRoom;

  // ── Realtime game events ──────────────────────────────────────────────────

  final _eventController = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get gameEvents => _eventController.stream;

  StreamSubscription? _realtimeSub;

  /// Subscribe to real-time events for a room
  void subscribeToRoom(String roomId) {
    // Real implementation:
    // _realtimeSub = supabase
    //   .from('game_events')
    //   .stream(primaryKey: ['id'])
    //   .eq('room_id', roomId)
    //   .listen((data) {
    //     for (final row in data) {
    //       _eventController.add(GameEvent.fromJson(row));
    //     }
    //   });
  }

  void unsubscribe() {
    _realtimeSub?.cancel();
    _realtimeSub = null;
  }

  /// Broadcast a game event (dice roll, token move, etc.)
  Future<void> broadcastEvent(GameEvent event) async {
    // Real: await supabase.from('game_events').insert(event.toJson())
    // Route chat events to callback, others to stream
    if (event.type == 'chat') {
      onChatEvent?.call(event.payload);
    } else {
      _eventController.add(event); // local echo for stub
    }
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  /// Called when a remote player sends a chat message over Realtime
  void Function(Map<String, dynamic> chatPayload)? onChatEvent;

  /// Broadcast a chat message to all players in the room
  Future<void> broadcastChat({
    required String playerName,
    required int playerIndex,
    required String content,
    required String type,
    required String messageId,
    required String timestamp,
  }) async {
    await broadcastEvent(GameEvent(
      type: 'chat',
      playerId: '$playerIndex',
      payload: {
        'id': messageId,
        'playerName': playerName,
        'playerIndex': playerIndex,
        'content': content,
        'type': type,
        'timestamp': timestamp,
      },
    ));
  }

  // ── Leaderboard ───────────────────────────────────────────────────────────

  Future<List<LeaderboardEntry>> fetchGlobalLeaderboard({int limit = 20}) async {
    // Real: supabase.from('profiles').select().order('wins', ascending: false).limit(limit)
    return _mockLeaderboard(limit);
  }

  Future<List<LeaderboardEntry>> fetchWeeklyLeaderboard({int limit = 20}) async {
    return _mockLeaderboard(limit)
      ..sort((a, b) => b.weeklyWins.compareTo(a.weeklyWins));
  }

  Future<void> updateProfile({
    required int wins,
    required int losses,
    required int coins,
    required int xp,
    required int level,
  }) async {
    // Real: supabase.from('profiles').update({...}).eq('id', _currentUserId)
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  String _generateUuid() {
    final rand = Random.secure();
    final bytes = List.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    return [
      bytes.sublist(0, 4),
      bytes.sublist(4, 6),
      bytes.sublist(6, 8),
      bytes.sublist(8, 10),
      bytes.sublist(10, 16),
    ]
        .map((b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join())
        .join('-');
  }

  List<LeaderboardEntry> _mockLeaderboard(int limit) {
    final names = [
      ('DragonSlayer', '🐉', 428, 38),
      ('LudoMaster', '👑', 391, 42),
      ('StrategyKing', '⚔️', 355, 35),
      ('SwiftMover', '⚡', 302, 28),
      ('TokenCutter', '✂️', 278, 24),
      ('BoardWizard', '🧙', 241, 20),
      ('DiceRoller', '🎲', 198, 16),
      ('QuickPlayer', '🏃', 165, 13),
      ('SafeZonePro', '🛡️', 134, 10),
      ('YoungStar', '⭐', 98, 7),
    ];
    return names
        .take(limit)
        .toList()
        .asMap()
        .entries
        .map((e) => LeaderboardEntry(
              rank: e.key + 1,
              userId: _generateUuid(),
              username: e.value.$1,
              avatarEmoji: e.value.$2,
              wins: e.value.$3,
              weeklyWins: (e.value.$3 * 0.15).round(),
              level: e.value.$4,
            ))
        .toList();
  }

  void dispose() {
    unsubscribe();
    _eventController.close();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

enum RoomStatus { waiting, starting, inProgress, finished }

class OnlineRoom {
  final String id;
  final String code;
  final String hostId;
  final String hostName;
  final String gameMode;
  final int turnTimer;
  final int maxPlayers;
  final List<RoomPlayer> players;
  RoomStatus status;

  OnlineRoom({
    required this.id,
    required this.code,
    required this.hostId,
    required this.hostName,
    required this.gameMode,
    required this.turnTimer,
    required this.maxPlayers,
    required this.players,
    required this.status,
  });

  bool get isFull => players.length >= maxPlayers;
  bool get allReady => players.every((p) => p.isReady);

  Map<String, dynamic> toJson() => {
        'id': id,
        'room_code': code,
        'host_id': hostId,
        'game_mode': gameMode,
        'turn_timer': turnTimer,
        'max_players': maxPlayers,
        'status': status.name,
      };
}

class RoomPlayer {
  final String id;
  final String name;
  final int index;
  bool isReady;
  final bool isHost;

  RoomPlayer({
    required this.id,
    required this.name,
    required this.index,
    required this.isReady,
    required this.isHost,
  });
}

class GameEvent {
  final String type; // 'roll', 'move', 'cut', 'win', 'chat'
  final String playerId;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  GameEvent({
    required this.type,
    required this.playerId,
    required this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'event_type': type,
        'player_id': playerId,
        'payload': payload,
        'created_at': timestamp.toIso8601String(),
      };

  factory GameEvent.fromJson(Map<String, dynamic> json) => GameEvent(
        type: json['event_type'] as String,
        playerId: json['player_id'] as String,
        payload: json['payload'] as Map<String, dynamic>,
        timestamp: DateTime.parse(json['created_at'] as String),
      );
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String avatarEmoji;
  final int wins;
  final int weeklyWins;
  final int level;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.avatarEmoji,
    required this.wins,
    required this.weeklyWins,
    required this.level,
  });
}
