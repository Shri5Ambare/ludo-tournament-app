// lib/providers/chat_provider.dart
//
// Chat state management for in-game chat.
// Works for both LAN/Hotspot and Online multiplayer.
// Local pass-and-play mode also gets emoji reactions.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/board_paths.dart';

// ─── Message model ─────────────────────────────────────────────────────────

enum ChatMessageType { text, emoji, system }

class ChatMessage {
  final String id;
  final String playerName;
  final int playerIndex; // 0-3 for color coding
  final String content;
  final ChatMessageType type;
  final DateTime timestamp;
  final bool isSelf; // did the local player send this?

  const ChatMessage({
    required this.id,
    required this.playerName,
    required this.playerIndex,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isSelf = false,
  });

  bool get isEmoji => type == ChatMessageType.emoji;
  bool get isSystem => type == ChatMessageType.system;

  Color get playerColor => playerIndex >= 0 && playerIndex < 4
      ? BoardPaths.playerColors[playerIndex]
      : const Color(0xFF6C3CE1);

  factory ChatMessage.text({
    required String playerName,
    required int playerIndex,
    required String content,
    bool isSelf = false,
  }) {
    return ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_$playerIndex',
      playerName: playerName,
      playerIndex: playerIndex,
      content: content,
      type: ChatMessageType.text,
      timestamp: DateTime.now(),
      isSelf: isSelf,
    );
  }

  factory ChatMessage.emoji({
    required String playerName,
    required int playerIndex,
    required String emoji,
    bool isSelf = false,
  }) {
    return ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_emoji_$playerIndex',
      playerName: playerName,
      playerIndex: playerIndex,
      content: emoji,
      type: ChatMessageType.emoji,
      timestamp: DateTime.now(),
      isSelf: isSelf,
    );
  }

  factory ChatMessage.system(String content) {
    return ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_sys',
      playerName: 'System',
      playerIndex: -1,
      content: content,
      type: ChatMessageType.system,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerName': playerName,
        'playerIndex': playerIndex,
        'content': content,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        playerName: json['playerName'] as String,
        playerIndex: json['playerIndex'] as int,
        content: json['content'] as String,
        type: ChatMessageType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ChatMessageType.text,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        isSelf: false, // remote messages are never self
      );
}

// ─── Chat state ─────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isOpen;
  final int unreadCount;

  const ChatState({
    this.messages = const [],
    this.isOpen = false,
    this.unreadCount = 0,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isOpen,
    int? unreadCount,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isOpen: isOpen ?? this.isOpen,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

// ─── Provider ───────────────────────────────────────────────────────────────

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState());

  // Callback called when local player sends a message — wire to LAN/Online
  void Function(ChatMessage)? onSend;

  // Max messages kept in memory
  static const _maxMessages = 100;

  /// Open / close the chat panel
  void toggleChat() {
    state = state.copyWith(
      isOpen: !state.isOpen,
      unreadCount: state.isOpen ? state.unreadCount : 0,
    );
  }

  void openChat() {
    state = state.copyWith(isOpen: true, unreadCount: 0);
  }

  void closeChat() {
    state = state.copyWith(isOpen: false);
  }

  /// Send a text message (from local player)
  void sendText({
    required String playerName,
    required int playerIndex,
    required String text,
  }) {
    final msg = ChatMessage.text(
      playerName: playerName,
      playerIndex: playerIndex,
      content: text.trim(),
      isSelf: true,
    );
    _addMessage(msg, isSelf: true);
    onSend?.call(msg);
  }

  /// Send an emoji reaction (from local player)
  void sendEmoji({
    required String playerName,
    required int playerIndex,
    required String emoji,
  }) {
    final msg = ChatMessage.emoji(
      playerName: playerName,
      playerIndex: playerIndex,
      emoji: emoji,
      isSelf: true,
    );
    _addMessage(msg, isSelf: true);
    onSend?.call(msg);
  }

  /// Receive a message from a remote player (LAN / Online)
  void receiveMessage(ChatMessage msg) {
    _addMessage(msg, isSelf: false);
  }

  /// Receive from raw JSON (LAN WebSocket payload)
  void receiveFromJson(Map<String, dynamic> json) {
    try {
      final msg = ChatMessage.fromJson(json);
      receiveMessage(msg);
    } catch (_) {}
  }

  /// Add a system message (e.g. "Player joined", "Game started")
  void addSystemMessage(String content) {
    _addMessage(ChatMessage.system(content), isSelf: false);
  }

  /// Clear all messages (call when game ends or resets)
  void clear() {
    state = const ChatState();
  }

  void _addMessage(ChatMessage msg, {required bool isSelf}) {
    final msgs = [...state.messages, msg];
    // Keep bounded
    final trimmed = msgs.length > _maxMessages
        ? msgs.sublist(msgs.length - _maxMessages)
        : msgs;

    final newUnread =
        (!state.isOpen && !isSelf) ? state.unreadCount + 1 : state.unreadCount;

    state = state.copyWith(messages: trimmed, unreadCount: newUnread);
  }
}
