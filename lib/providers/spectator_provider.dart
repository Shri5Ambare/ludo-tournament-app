// lib/providers/spectator_provider.dart
//
// Spectator mode state management.
// Spectators join a room read-only, see the live board + event log,
// and have their own chat channel separate from players.
//
// Transport: stub mirrors the LAN/Supabase patterns.
// Real impl: subscribe to Supabase Realtime 'game_events' + 'spectators' tables.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart';
import '../core/constants/app_constants.dart';

// ─── Spectator models ────────────────────────────────────────────────────────

class SpectatorInfo {
  final String id;
  final String username;
  final String avatarEmoji;
  final DateTime joinedAt;

  const SpectatorInfo({
    required this.id,
    required this.username,
    required this.avatarEmoji,
    required this.joinedAt,
  });
}

class SpectatorChatMessage {
  final String id;
  final String username;
  final String avatarEmoji;
  final String content;
  final bool isEmoji;
  final bool isSelf;
  final DateTime timestamp;

  const SpectatorChatMessage({
    required this.id,
    required this.username,
    required this.avatarEmoji,
    required this.content,
    required this.isEmoji,
    required this.isSelf,
    required this.timestamp,
  });

  factory SpectatorChatMessage.text({
    required String username,
    required String avatarEmoji,
    required String content,
    bool isSelf = false,
  }) =>
      SpectatorChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_$username',
        username: username,
        avatarEmoji: avatarEmoji,
        content: content,
        isEmoji: false,
        isSelf: isSelf,
        timestamp: DateTime.now(),
      );

  factory SpectatorChatMessage.emoji({
    required String username,
    required String avatarEmoji,
    required String emoji,
    bool isSelf = false,
  }) =>
      SpectatorChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_emoji_$username',
        username: username,
        avatarEmoji: avatarEmoji,
        content: emoji,
        isEmoji: true,
        isSelf: isSelf,
        timestamp: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'avatarEmoji': avatarEmoji,
        'content': content,
        'isEmoji': isEmoji,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SpectatorChatMessage.fromJson(Map<String, dynamic> json,
      {bool isSelf = false}) =>
      SpectatorChatMessage(
        id: json['id'] as String,
        username: json['username'] as String,
        avatarEmoji: json['avatarEmoji'] as String? ?? '👀',
        content: json['content'] as String,
        isEmoji: json['isEmoji'] as bool? ?? false,
        isSelf: isSelf,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

// ─── State ───────────────────────────────────────────────────────────────────

enum SpectatorConnectionStatus { connecting, connected, disconnected, error }

class SpectatorState {
  final SpectatorConnectionStatus connectionStatus;
  final String roomCode;
  final GameState? gameState; // live mirror of the game
  final List<SpectatorInfo> spectators;
  final List<SpectatorChatMessage> chatMessages;
  final bool chatOpen;
  final int unreadChat;
  final String? errorMessage;

  const SpectatorState({
    this.connectionStatus = SpectatorConnectionStatus.connecting,
    this.roomCode = '',
    this.gameState,
    this.spectators = const [],
    this.chatMessages = const [],
    this.chatOpen = false,
    this.unreadChat = 0,
    this.errorMessage,
  });

  int get spectatorCount => spectators.length;

  SpectatorState copyWith({
    SpectatorConnectionStatus? connectionStatus,
    String? roomCode,
    GameState? gameState,
    List<SpectatorInfo>? spectators,
    List<SpectatorChatMessage>? chatMessages,
    bool? chatOpen,
    int? unreadChat,
    String? errorMessage,
  }) =>
      SpectatorState(
        connectionStatus: connectionStatus ?? this.connectionStatus,
        roomCode: roomCode ?? this.roomCode,
        gameState: gameState ?? this.gameState,
        spectators: spectators ?? this.spectators,
        chatMessages: chatMessages ?? this.chatMessages,
        chatOpen: chatOpen ?? this.chatOpen,
        unreadChat: unreadChat ?? this.unreadChat,
        errorMessage: errorMessage,
      );
}

// ─── Provider ────────────────────────────────────────────────────────────────

final spectatorProvider =
    StateNotifierProvider<SpectatorNotifier, SpectatorState>((ref) {
  return SpectatorNotifier();
});

class SpectatorNotifier extends StateNotifier<SpectatorState> {
  SpectatorNotifier() : super(const SpectatorState());

  Timer? _simulationTimer;
  int _simTick = 0;

  // ── Connection ────────────────────────────────────────────────────────────

  Future<void> joinRoom({
    required String roomCode,
    required String myUsername,
    required String myAvatarEmoji,
    required String myId,
  }) async {
    state = state.copyWith(
      connectionStatus: SpectatorConnectionStatus.connecting,
      roomCode: roomCode,
    );

    // Stub: simulate network join delay
    // Real: await supabase.from('spectators').insert({...})
    //       then subscribe to 'game_events' Realtime channel
    await Future.delayed(const Duration(milliseconds: 800));

    final me = SpectatorInfo(
      id: myId,
      username: myUsername,
      avatarEmoji: myAvatarEmoji,
      joinedAt: DateTime.now(),
    );

    state = state.copyWith(
      connectionStatus: SpectatorConnectionStatus.connected,
      spectators: [..._mockSpectators, me],
      gameState: _generateMockGameState(),
    );

    // Start simulating live game state updates
    _startSimulation();

    // System welcome message
    _addSystemMessage('👀 You joined as a spectator');
    _addSystemMessage('💬 Spectator chat is only visible to other spectators');
  }

  void leaveRoom() {
    _simulationTimer?.cancel();
    // Real: await supabase.from('spectators').delete().eq('id', myId)
    state = const SpectatorState();
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  void toggleChat() {
    state = state.copyWith(
      chatOpen: !state.chatOpen,
      unreadChat: state.chatOpen ? state.unreadChat : 0,
    );
  }

  void closeChat() => state = state.copyWith(chatOpen: false);

  void sendText({required String username, required String avatarEmoji, required String text}) {
    final msg = SpectatorChatMessage.text(
      username: username,
      avatarEmoji: avatarEmoji,
      content: text.trim(),
      isSelf: true,
    );
    _addChat(msg);
    // Real: supabase.from('spectator_chat').insert(msg.toJson())
  }

  void sendEmoji({required String username, required String avatarEmoji, required String emoji}) {
    final msg = SpectatorChatMessage.emoji(
      username: username,
      avatarEmoji: avatarEmoji,
      emoji: emoji,
      isSelf: true,
    );
    _addChat(msg);
  }

  void receiveChat(Map<String, dynamic> json) {
    try {
      final msg = SpectatorChatMessage.fromJson(json);
      _addChat(msg);
    } catch (_) {}
  }

  void _addChat(SpectatorChatMessage msg) {
    final msgs = [...state.chatMessages, msg];
    final trimmed = msgs.length > 100 ? msgs.sublist(msgs.length - 100) : msgs;
    final newUnread = (!state.chatOpen && !msg.isSelf)
        ? state.unreadChat + 1
        : state.unreadChat;
    state = state.copyWith(chatMessages: trimmed, unreadChat: newUnread);
  }

  void _addSystemMessage(String text) {
    _addChat(SpectatorChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_sys',
      username: 'System',
      avatarEmoji: '⚙️',
      content: text,
      isEmoji: false,
      isSelf: false,
      timestamp: DateTime.now(),
    ));
  }

  // ── Receive live game state (from Realtime / LAN relay) ───────────────────

  void updateGameState(GameState newState) {
    state = state.copyWith(gameState: newState);
  }

  void addSpectator(SpectatorInfo spectator) {
    if (state.spectators.any((s) => s.id == spectator.id)) return;
    state = state.copyWith(spectators: [...state.spectators, spectator]);
    _addSystemMessage('${spectator.avatarEmoji} ${spectator.username} joined spectating');
  }

  void removeSpectator(String spectatorId) {
    final idx = state.spectators.indexWhere((s) => s.id == spectatorId);
    final removed = idx >= 0 ? state.spectators[idx] : null;
    state = state.copyWith(
      spectators: state.spectators.where((s) => s.id != spectatorId).toList(),
    );
    if (removed != null) {
      _addSystemMessage('${removed.avatarEmoji} ${removed.username} left');
    }
  }

  // ── Simulation (stub live game updates) ──────────────────────────────────

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _simTick++;
      // Simulate dice rolls and mock chat messages
      if (_simTick % 3 == 0 && state.chatMessages.length < 20) {
        const msgs = _mockChatLines;
        final line = msgs[_simTick % msgs.length];
        _addChat(SpectatorChatMessage.text(
          username: line.$1,
          avatarEmoji: line.$2,
          content: line.$3,
        ));
      }
      // Simulate a new spectator joining occasionally
      if (_simTick == 5) {
        addSpectator(SpectatorInfo(
          id: 'sim_new',
          username: 'BoardWatcher',
          avatarEmoji: '🎯',
          joinedAt: DateTime.now(),
        ));
      }
    });
  }

  // ── Mock data ─────────────────────────────────────────────────────────────

  static final _mockSpectators = [
    SpectatorInfo(id: 's1', username: 'LudoFan', avatarEmoji: '👀',
        joinedAt: DateTime.now().subtract(const Duration(minutes: 5))),
    SpectatorInfo(id: 's2', username: 'GameWatcher', avatarEmoji: '🍿',
        joinedAt: DateTime.now().subtract(const Duration(minutes: 2))),
  ];

  static const _mockChatLines = [
    ('LudoFan', '👀', 'Wow, great move! 🔥'),
    ('GameWatcher', '🍿', 'Go DragonSlayer!!'),
    ('LudoFan', '👀', 'That was close 😮'),
    ('GameWatcher', '🍿', 'Token cut incoming!'),
    ('LudoFan', '👀', 'This game is intense!'),
  ];

  GameState _generateMockGameState() {
    // Generate a mid-game state so spectators see a live board
    List<Token> buildTokens(int playerIndex) => List.generate(
          4,
          (i) => Token(
            id: playerIndex * 4 + i,
            playerIndex: playerIndex,
            state: i == 0 ? TokenState.active : TokenState.home,
            position: i == 0 ? 10 + playerIndex * 13 : 0,
          ),
        );

    final players = [
      Player(name: 'DragonSlayer99', index: 0, avatarEmoji: '🐉', tokens: buildTokens(0)),
      Player(name: 'LuckyDice',      index: 1, avatarEmoji: '🎲', tokens: buildTokens(1)),
      Player(name: 'NepaliGamer',    index: 2, avatarEmoji: '🏔️', tokens: buildTokens(2)),
      Player(name: 'QueenOfLudo',    index: 3, avatarEmoji: '👑', tokens: buildTokens(3)),
    ];

    return GameState(
      players: players,
      currentPlayerIndex: 0,
      diceValue: 4,
      gameMode: GameMode.classic,
      movableTokenIds: const [],
      turnTimeSeconds: 30,
      remainingTurnSeconds: 18,
      eventLog: const [
        '🐉 DragonSlayer99 rolled 6',
        '🎲 LuckyDice cut a token!',
        '🏔️ NepaliGamer moved to safe zone',
      ],
    );
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
