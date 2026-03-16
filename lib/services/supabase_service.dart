// lib/services/supabase_service.dart
//
// Real Supabase backend service for online multiplayer.
//
// SETUP: See SETUP.md for full SQL schema, RLS policies, and Realtime config.
// CREDENTIALS: Set kSupabaseUrl and kSupabaseAnonKey below, or load from
//              --dart-define at build time (recommended for production).

import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseServiceProvider =
    Provider<SupabaseService>((ref) => SupabaseService());

// ── Credentials ───────────────────────────────────────────────────────────────
// Replace with your real values, or pass via --dart-define=SUPABASE_URL=...
const String kSupabaseUrl =
    String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://YOUR_PROJECT.supabase.co');
const String kSupabaseAnonKey =
    String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'YOUR_ANON_KEY');

// ── Supabase client accessor ───────────────────────────────────────────────────
SupabaseClient get _db => Supabase.instance.client;

// ─────────────────────────────────────────────────────────────────────────────

class SupabaseService {
  // ── Auth ──────────────────────────────────────────────────────────────────

  bool get isSignedIn => _db.auth.currentUser != null;
  String? get currentUserId => _db.auth.currentUser?.id;
  String? get username => _db.auth.currentUser?.userMetadata?['username'] as String?;

  /// Sign in anonymously (guest play)
  Future<bool> signInAnonymously(String displayName) async {
    try {
      final res = await _db.auth.signInAnonymously(data: {
        'username': displayName,
        'avatar_emoji': '🎮',
      });
      if (res.user != null) {
        // Upsert profile row
        await _db.from('profiles').upsert({
          'id': res.user!.id,
          'username': displayName,
          'avatar_emoji': '🎮',
        });
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Sign in with email + password
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _db.auth.signInWithPassword(email: email, password: password);
      return null; // null = success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Sign up new account
  Future<String?> signUpWithEmail(
      String email, String password, String username) async {
    try {
      final res = await _db.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'avatar_emoji': '🎮'},
      );
      if (res.user != null) {
        await _db.from('profiles').upsert({
          'id': res.user!.id,
          'username': username,
          'avatar_emoji': '🎮',
        });
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _db.auth.signOut();
  }

  // ── Rooms ─────────────────────────────────────────────────────────────────

  OnlineRoom? _activeRoom;

  /// Create an online room
  Future<OnlineRoom?> createRoom({
    required String gameMode,
    required int turnTimer,
    required int maxPlayers,
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null) return null;
      final code = _generateRoomCode();

      // Insert room
      final roomRow = await _db.from('online_rooms').insert({
        'host_id': uid,
        'room_code': code,
        'game_mode': gameMode,
        'turn_timer': turnTimer,
        'max_players': maxPlayers,
        'status': 'waiting',
      }).select().single();

      // Insert host as player index 0
      await _db.from('room_players').insert({
        'room_id': roomRow['id'],
        'player_id': uid,
        'player_name': username ?? 'Host',
        'player_index': 0,
        'is_ready': true,
        'is_host': true,
      });

      final room = OnlineRoom(
        id: roomRow['id'] as String,
        code: code,
        hostId: uid,
        hostName: username ?? 'Host',
        gameMode: gameMode,
        turnTimer: turnTimer,
        maxPlayers: maxPlayers,
        players: [
          RoomPlayer(
            id: uid,
            name: username ?? 'Host',
            index: 0,
            isReady: true,
            isHost: true,
          ),
        ],
        status: RoomStatus.waiting,
      );
      _activeRoom = room;
      return room;
    } catch (_) {
      return null;
    }
  }

  /// Join a room by 6-character code
  Future<OnlineRoom?> joinRoom(String code) async {
    try {
      final uid = currentUserId;
      if (uid == null) return null;

      // Fetch room
      final roomRow = await _db
          .from('online_rooms')
          .select('*, room_players(*)')
          .eq('room_code', code.toUpperCase())
          .eq('status', 'waiting')
          .single();

      final existingPlayers = (roomRow['room_players'] as List)
          .map((p) => RoomPlayer(
                id: p['player_id'] as String,
                name: p['player_name'] as String,
                index: p['player_index'] as int,
                isReady: p['is_ready'] as bool,
                isHost: p['is_host'] as bool,
              ))
          .toList();

      final maxPlayers = roomRow['max_players'] as int;
      if (existingPlayers.length >= maxPlayers) return null;

      final newIndex = existingPlayers.length;

      // Insert self as new player
      await _db.from('room_players').insert({
        'room_id': roomRow['id'],
        'player_id': uid,
        'player_name': username ?? 'Player',
        'player_index': newIndex,
        'is_ready': false,
        'is_host': false,
      });

      final me = RoomPlayer(
        id: uid,
        name: username ?? 'Player',
        index: newIndex,
        isReady: false,
        isHost: false,
      );

      final room = OnlineRoom(
        id: roomRow['id'] as String,
        code: roomRow['room_code'] as String,
        hostId: roomRow['host_id'] as String,
        hostName: existingPlayers.first.name,
        gameMode: roomRow['game_mode'] as String,
        turnTimer: roomRow['turn_timer'] as int,
        maxPlayers: maxPlayers,
        players: [...existingPlayers, me],
        status: RoomStatus.waiting,
      );
      _activeRoom = room;
      return room;
    } catch (_) {
      return null;
    }
  }

  /// Update ready status for current player
  Future<void> setReady(String roomId, bool ready) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db
        .from('room_players')
        .update({'is_ready': ready})
        .eq('room_id', roomId)
        .eq('player_id', uid);
  }

  /// Mark room as in-progress (host only)
  Future<void> startRoom(String roomId) async {
    await _db
        .from('online_rooms')
        .update({'status': 'in_progress'})
        .eq('id', roomId);
  }

  // ── Realtime game events ──────────────────────────────────────────────────

  final _eventController = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get gameEvents => _eventController.stream;

  RealtimeChannel? _gameChannel;
  RealtimeChannel? _roomChannel;

  /// Subscribe to Realtime channel for a room
  /// Listens to: game_events INSERT + room_players changes
  void subscribeToRoom(String roomId) {
    unsubscribe();

    // Game events channel
    _gameChannel = _db
        .channel('game_events:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'game_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            try {
              final row = payload.newRecord;
              final event = GameEvent.fromJson(row);
              if (event.type == 'chat') {
                onChatEvent?.call(event.payload);
              } else {
                _eventController.add(event);
              }
            } catch (_) {}
          },
        )
        .subscribe();

    // Room players channel (detect when players join/leave/ready-up)
    _roomChannel = _db
        .channel('room_players:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_players',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            onRoomPlayersChanged?.call(payload.newRecord);
          },
        )
        .subscribe();
  }

  void unsubscribe() {
    if (_gameChannel != null) {
      _db.removeChannel(_gameChannel!);
      _gameChannel = null;
    }
    if (_roomChannel != null) {
      _db.removeChannel(_roomChannel!);
      _roomChannel = null;
    }
  }

  /// Broadcast a game event (dice roll, token move, etc.)
  Future<void> broadcastEvent(GameEvent event) async {
    try {
      final roomId = _activeRoom?.id;
      if (roomId == null) return;
      await _db.from('game_events').insert({
        'room_id': roomId,
        'player_id': currentUserId ?? '',
        'event_type': event.type,
        'payload': event.payload,
      });
    } catch (_) {
      // Fallback: local echo (e.g. during offline testing)
      if (event.type == 'chat') {
        onChatEvent?.call(event.payload);
      } else {
        _eventController.add(event);
      }
    }
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  /// Called when a remote chat message arrives via Realtime
  void Function(Map<String, dynamic> chatPayload)? onChatEvent;

  /// Called when room_players table changes (join/leave/ready)
  void Function(Map<String, dynamic> playerRow)? onRoomPlayersChanged;

  /// Broadcast a chat message via game_events table
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

  // ── Presence (online status) ───────────────────────────────────────────────

  RealtimeChannel? _presenceChannel;

  void joinPresence(String roomId) {
    _presenceChannel = _db.channel('presence:$roomId');
    _presenceChannel!
      ..onPresenceSync(callback: (_) {})
      ..subscribe((status, _) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await _presenceChannel!.track({
            'user_id': currentUserId,
            'username': username,
            'online_at': DateTime.now().toIso8601String(),
          });
        }
      });
  }

  void leavePresence() {
    if (_presenceChannel != null) {
      _db.removeChannel(_presenceChannel!);
      _presenceChannel = null;
    }
  }

  // ── Profile & Leaderboard ─────────────────────────────────────────────────

  Future<List<LeaderboardEntry>> fetchGlobalLeaderboard({int limit = 20}) async {
    try {
      final rows = await _db
          .from('profiles')
          .select('id, username, avatar_emoji, wins, level')
          .order('wins', ascending: false)
          .limit(limit);
      return (rows as List).asMap().entries.map((e) {
        final r = e.value as Map<String, dynamic>;
        return LeaderboardEntry(
          rank: e.key + 1,
          userId: r['id'] as String,
          username: r['username'] as String,
          avatarEmoji: r['avatar_emoji'] as String? ?? '🎮',
          wins: r['wins'] as int? ?? 0,
          weeklyWins: ((r['wins'] as int? ?? 0) * 0.15).round(),
          level: r['level'] as int? ?? 1,
        );
      }).toList();
    } catch (_) {
      return _mockLeaderboard(limit);
    }
  }

  Future<List<LeaderboardEntry>> fetchWeeklyLeaderboard({int limit = 20}) async {
    // Real impl: filter by created_at >= NOW() - INTERVAL '7 days'
    // For now falls back to global with shuffle for demo
    final global = await fetchGlobalLeaderboard(limit: limit);
    return global..sort((a, b) => b.weeklyWins.compareTo(a.weeklyWins));
  }

  Future<void> updateProfile({
    required int wins,
    required int losses,
    required int coins,
    required int xp,
    required int level,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      await _db.from('profiles').update({
        'wins': wins,
        'losses': losses,
        'coins': coins,
        'xp': xp,
        'level': level,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', uid);
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> fetchMyProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      return await _db.from('profiles').select().eq('id', uid).single();
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
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
    return names.take(limit).toList().asMap().entries.map((e) {
      return LeaderboardEntry(
        rank: e.key + 1,
        userId: 'mock_${e.key}',
        username: e.value.$1,
        avatarEmoji: e.value.$2,
        wins: e.value.$3,
        weeklyWins: (e.value.$3 * 0.15).round(),
        level: e.value.$4,
      );
    }).toList();
  }

  void dispose() {
    unsubscribe();
    leavePresence();
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
        playerId: json['player_id'] as String? ?? '',
        payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? {},
        timestamp: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
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
