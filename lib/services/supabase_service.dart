// lib/services/supabase_service.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game_models.dart';
import '../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
const kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://alndzkomsgfzqxhuctrr.supabase.co',
);
const kSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFsbmR6a29tc2dmenF4aHVjdHJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwOTg2NTAsImV4cCI6MjA4OTY3NDY1MH0.RAcNCA31ZvmGYTfZVsC6uRGv_etE99vgo0Y-UJXr964',
);

// ─────────────────────────────────────────────────────────────────────────────
class ConnectionResult {
  final bool success;
  final String message;
  final String? details;

  ConnectionResult(this.success, this.message, {this.details});
}

class SupabaseService {
  final _db = Supabase.instance.client;

  // ── Auth ──────────────────────────────────────────────────────────────────

  bool get isSignedIn => _db.auth.currentUser != null;
  String? get currentUserId => _db.auth.currentUser?.id;
  String? get username => _db.auth.currentUser?.userMetadata?['username'] as String?;
  Stream<AuthState> get authStateChanges => _db.auth.onAuthStateChange;

  /// Detailed connection check
  Future<ConnectionResult> testConnection() async {
    try {
      if (kSupabaseUrl.contains('YOUR_PROJECT')) {
        return ConnectionResult(false, 'Configuration Error', 
            details: 'The Supabase URL is still set to placeholder. Update kSupabaseUrl in lib/services/supabase_service.dart.');
      }
      final stopwatch = Stopwatch()..start();
      await _db.from('profiles').select('id').limit(1);
      stopwatch.stop();
      return ConnectionResult(true, 'Connected Successfully', 
          details: 'Ping: ${stopwatch.elapsedMilliseconds}ms\nProject: ${Uri.parse(kSupabaseUrl).host}');
    } on TimeoutException {
      return ConnectionResult(false, 'Connection Timeout', details: 'Check your internet connection.');
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST301') return ConnectionResult(false, 'Invalid API Key');
      return ConnectionResult(false, 'Database Error', details: '[${e.code}] ${e.message}');
    } catch (e) {
      return ConnectionResult(false, 'Initialization Failed', details: e.toString());
    }
  }

  /// Sign in anonymously (guest play)
  Future<String?> signInAnonymously(String username) async {
    try {
      final response = await _db.auth.signInAnonymously(
        data: {'username': username, 'avatar_emoji': '🎮'},
      );
      if (response.user != null) {
        await _db.from('profiles').upsert({
          'id': response.user!.id,
          'username': username,
          'avatar_emoji': '🎮',
          'updated_at': DateTime.now().toIso8601String(),
        });
        return null;
      }
      return 'Sign-in failed';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async => await _db.auth.signOut();

  Future<String?> signUpWithEmail(String email, String password, String username) async {
    try {
      final response = await _db.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'avatar_emoji': '😊'},
      );
      if (response.user != null) {
        await _db.from('profiles').upsert({
          'id': response.user!.id,
          'username': username,
          'avatar_emoji': '😊',
          'updated_at': DateTime.now().toIso8601String(),
        });
        return null; // success
      }
      return 'Sign up failed';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      final response = await _db.auth.signInWithPassword(email: email, password: password);
      if (response.user != null) return null; // success
      return 'Sign in failed';
    } catch (e) {
      return e.toString();
    }
  }

  // ── Rooms ─────────────────────────────────────────────────────────────────

  OnlineRoom? _activeRoom;
  OnlineRoom? get activeRoom => _activeRoom;

  Future<OnlineRoom?> createRoom({
    required String gameMode,
    required int turnTimer,
    required int maxPlayers,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;
    final code = _generateRoomCode();
    try {
      final roomData = await _db.from('online_rooms').insert({
        'room_code': code,
        'host_id': uid,
        'game_mode': gameMode,
        'turn_timer': turnTimer,
        'max_players': maxPlayers,
        'status': 'waiting',
      }).select().single();

      await _db.from('room_players').insert({
        'room_id': roomData['id'],
        'player_id': uid,
        'player_index': 0,
        'is_ready': true,
      });

      _activeRoom = OnlineRoom.fromMap(roomData, []);
      return _activeRoom;
    } catch (e) {
      debugPrint('Create room error: $e');
      return null;
    }
  }

  Future<OnlineRoom?> joinRoom(String roomCode) async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      final roomData = await _db.from('online_rooms')
          .select()
          .eq('room_code', roomCode.toUpperCase())
          .eq('status', 'waiting')
          .single();

      final existingPlayers = await getRoomPlayers(roomData['id']);
      if (existingPlayers.length >= roomData['max_players']) {
        throw 'Room is full';
      }

      await _db.from('room_players').insert({
        'room_id': roomData['id'],
        'player_id': uid,
        'player_index': existingPlayers.length,
        'is_ready': false,
      });

      _activeRoom = OnlineRoom.fromMap(roomData, existingPlayers);
      return _activeRoom;
    } catch (e) {
      debugPrint('Join room error: $e');
      rethrow;
    }
  }

  Future<List<RoomPlayer>> getRoomPlayers(String roomId) async {
    final playersData = await _db.from('room_players')
        .select('*, profiles(username, avatar_emoji)')
        .eq('room_id', roomId);
    
    return (playersData as List).map((p) => RoomPlayer(
      id: p['player_id'],
      name: p['profiles']['username'] ?? 'Player',
      index: p['player_index'],
      isReady: p['is_ready'],
      isHost: false, // Will be determined by host_id check if needed
      avatarEmoji: p['profiles']['avatar_emoji'] ?? '🎮',
    )).toList();
  }

  Future<void> updateRoomSettings(String roomId, {
    String? gameMode,
    int? maxPlayers,
    int? turnTimer,
    RoomStatus? status,
  }) async {
    final Map<String, dynamic> updates = {};
    if (gameMode != null) updates['game_mode'] = gameMode;
    if (maxPlayers != null) updates['max_players'] = maxPlayers;
    if (turnTimer != null) updates['turn_timer'] = turnTimer;
    if (status != null) updates['status'] = status.name;
    if (updates.isEmpty) return;
    try {
      await _db.from('online_rooms').update(updates).eq('id', roomId);
    } catch (_) {}
  }

  Future<void> updateRoomRules(String roomId, CustomRules rules) async {
    try {
      await _db.from('online_rooms').update({'custom_rules': rules.toJson()}).eq('id', roomId);
    } catch (_) {}
  }

  // ── Realtime ──────────────────────────────────────────────────────────────

  final _eventController = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get gameEvents => _eventController.stream;

  RealtimeChannel? _roomChannel;
  RealtimeChannel? _gameChannel;
  RealtimeChannel? _presenceChannel;

  void Function(Map<String, dynamic> chatPayload)? onChatEvent;
  void Function()? onRoomPlayersChanged;
  void Function(CustomRules rules)? onRulesChanged;
  void Function(RoomStatus status)? onRoomStatusChanged;

  void subscribeToRoom(String roomId) {
    unsubscribe();
    _gameChannel = _db.channel('game_events:$roomId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'game_events',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
        callback: (payload) {
          final event = GameEvent.fromJson(payload.newRecord);
          if (event.type == 'chat') {
            onChatEvent?.call(event.payload);
          } else {
            _eventController.add(event);
          }
        },
      ).subscribe();

    _roomChannel = _db.channel('room_updates:$roomId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'room_players',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
        callback: (_) => onRoomPlayersChanged?.call(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'online_rooms',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: roomId),
        callback: (payload) {
          final row = payload.newRecord;
          if (row['custom_rules'] != null) {
            onRulesChanged?.call(CustomRules.fromJson(row['custom_rules']));
          }
          if (row['status'] != null) {
            onRoomStatusChanged?.call(RoomStatus.values.firstWhere((e) => e.name == row['status'], orElse: () => RoomStatus.waiting));
          }
        },
      ).subscribe();
  }

  void unsubscribe() {
    if (_gameChannel != null) { _db.removeChannel(_gameChannel!); _gameChannel = null; }
    if (_roomChannel != null) { _db.removeChannel(_roomChannel!); _roomChannel = null; }
  }

  Future<void> broadcastEvent(GameEvent event) async {
    final roomId = _activeRoom?.id;
    if (roomId == null) return;
    try {
      await _db.from('game_events').insert({
        'room_id': roomId,
        'player_id': currentUserId ?? '',
        'event_type': event.type,
        'payload': event.payload,
      });
    } catch (_) {
      _eventController.add(event);
    }
  }

  Future<void> broadcastChat({
    required String playerName, required int playerIndex, required String content,
    required String type, required String messageId, required String timestamp,
  }) async {
    await broadcastEvent(GameEvent(
      type: 'chat',
      playerId: '$playerIndex',
      payload: {'id': messageId, 'playerName': playerName, 'playerIndex': playerIndex, 'content': content, 'type': type, 'timestamp': timestamp},
    ));
  }

  // ── Presence & Leaderboard ────────────────────────────────────────────────

  void joinPresence(String roomId) {
    _presenceChannel = _db.channel('presence:$roomId');
    _presenceChannel!..onPresenceSync((_) {})..subscribe((status, _) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _presenceChannel!.track({'user_id': currentUserId, 'username': username, 'online_at': DateTime.now().toIso8601String()});
      }
    });
  }

  Future<List<LeaderboardEntry>> fetchGlobalLeaderboard({int limit = 20}) async {
    try {
      final rows = await _db.from('profiles').select('id, username, avatar_emoji, wins, level').order('wins', ascending: false).limit(limit);
      return (rows as List).asMap().entries.map((e) {
        final r = e.value as Map<String, dynamic>;
        return LeaderboardEntry(
          rank: e.key + 1, userId: r['id'], username: r['username'], avatarEmoji: r['avatar_emoji'] ?? '🎮',
          wins: r['wins'] ?? 0, weeklyWins: ((r['wins'] ?? 0) * 0.15).round(), level: r['level'] ?? 1,
        );
      }).toList();
    } catch (_) { return []; }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[Random.secure().nextInt(chars.length)]).join();
  }

  void dispose() {
    unsubscribe();
    if (_presenceChannel != null) _db.removeChannel(_presenceChannel!);
    _eventController.close();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Models
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
  final RoomStatus status;
  final CustomRules customRules;

  OnlineRoom({
    required this.id, required this.code, required this.hostId, required this.hostName,
    required this.gameMode, required this.turnTimer, required this.maxPlayers,
    required this.players, required this.status, this.customRules = const CustomRules(),
  });

  factory OnlineRoom.fromMap(Map<String, dynamic> map, List<RoomPlayer> players) {
    return OnlineRoom(
      id: map['id'],
      code: map['room_code'],
      hostId: map['host_id'],
      hostName: 'Host',
      gameMode: map['game_mode'] ?? GameMode.classic,
      turnTimer: map['turn_timer'] ?? 30,
      maxPlayers: map['max_players'] ?? 4,
      players: players,
      status: RoomStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => RoomStatus.waiting),
      customRules: map['custom_rules'] != null ? CustomRules.fromJson(map['custom_rules']) : const CustomRules(),
    );
  }

  OnlineRoom copyWith({String? gameMode, int? maxPlayers, int? turnTimer, RoomStatus? status}) {
    return OnlineRoom(
      id: id,
      code: code,
      hostId: hostId,
      hostName: hostName,
      gameMode: gameMode ?? this.gameMode,
      turnTimer: turnTimer ?? this.turnTimer,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      players: players,
      status: status ?? this.status,
      customRules: customRules,
    );
  }
}

class RoomPlayer {
  final String id;
  final String name;
  final int index;
  final bool isReady;
  final bool isHost;
  final String avatarEmoji;
  RoomPlayer({required this.id, required this.name, required this.index, required this.isReady, required this.isHost, this.avatarEmoji = '🎮'});
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String avatarEmoji;
  final int wins;
  final int weeklyWins;
  final int level;
  LeaderboardEntry({required this.rank, required this.userId, required this.username, required this.avatarEmoji, required this.wins, required this.weeklyWins, required this.level});
}

class GameEvent {
  final String type;
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
    timestamp: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
  );
}

final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService());
