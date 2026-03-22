// lib/providers/friends_provider.dart
//
// Friend list state management.
// Covers: friend list, pending incoming/outgoing invites,
// online status, and game invites (invite-to-room).
//
// Uses SupabaseService as the transport stub — replace the
// stub methods with real Supabase Realtime calls when backend is live.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Models ─────────────────────────────────────────────────────────────────

enum FriendStatus { online, inGame, offline }

enum FriendRequestStatus { pending, accepted, rejected }

class Friend {
  final String id;
  final String username;
  final String avatarEmoji;
  final FriendStatus status;
  final int level;
  final int wins;
  final String? currentRoomCode; // non-null when inGame

  const Friend({
    required this.id,
    required this.username,
    required this.avatarEmoji,
    required this.status,
    required this.level,
    required this.wins,
    this.currentRoomCode,
  });

  Friend copyWith({
    String? id,
    String? username,
    String? avatarEmoji,
    FriendStatus? status,
    int? level,
    int? wins,
    String? currentRoomCode,
  }) =>
      Friend(
        id: id ?? this.id,
        username: username ?? this.username,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        status: status ?? this.status,
        level: level ?? this.level,
        wins: wins ?? this.wins,
        currentRoomCode: currentRoomCode ?? this.currentRoomCode,
      );

  Color get statusColor {
    switch (status) {
      case FriendStatus.online:
        return const Color(0xFF4CAF50);
      case FriendStatus.inGame:
        return const Color(0xFFFF9800);
      case FriendStatus.offline:
        return const Color(0xFF555577);
    }
  }

  String get statusLabel {
    switch (status) {
      case FriendStatus.online:
        return 'Online';
      case FriendStatus.inGame:
        return 'In Game';
      case FriendStatus.offline:
        return 'Offline';
    }
  }
}

class FriendRequest {
  final String id;
  final String fromId;
  final String fromUsername;
  final String fromAvatarEmoji;
  final FriendRequestStatus status;
  final DateTime sentAt;
  final bool isIncoming; // true = they sent to me, false = I sent to them

  const FriendRequest({
    required this.id,
    required this.fromId,
    required this.fromUsername,
    required this.fromAvatarEmoji,
    required this.status,
    required this.sentAt,
    required this.isIncoming,
  });
}

class GameInvite {
  final String id;
  final String fromId;
  final String fromUsername;
  final String fromAvatarEmoji;
  final String roomCode;
  final String gameMode;
  final DateTime sentAt;

  const GameInvite({
    required this.id,
    required this.fromId,
    required this.fromUsername,
    required this.fromAvatarEmoji,
    required this.roomCode,
    required this.gameMode,
    required this.sentAt,
  });
}

// ─── State ───────────────────────────────────────────────────────────────────

class FriendsState {
  final List<Friend> friends;
  final List<FriendRequest> pendingRequests; // incoming + outgoing
  final List<GameInvite> gameInvites;
  final bool isLoading;
  final String? searchQuery;
  final List<Friend> searchResults;
  final String? error;

  const FriendsState({
    this.friends = const [],
    this.pendingRequests = const [],
    this.gameInvites = const [],
    this.isLoading = false,
    this.searchQuery,
    this.searchResults = const [],
    this.error,
  });

  List<FriendRequest> get incoming =>
      pendingRequests.where((r) => r.isIncoming && r.status == FriendRequestStatus.pending).toList();
  List<FriendRequest> get outgoing =>
      pendingRequests.where((r) => !r.isIncoming && r.status == FriendRequestStatus.pending).toList();

  int get totalBadgeCount => incoming.length + gameInvites.length;

  List<Friend> get onlineFriends =>
      friends.where((f) => f.status != FriendStatus.offline).toList()
        ..sort((a, b) => a.status.index.compareTo(b.status.index));
  List<Friend> get offlineFriends =>
      friends.where((f) => f.status == FriendStatus.offline).toList();

  FriendsState copyWith({
    List<Friend>? friends,
    List<FriendRequest>? pendingRequests,
    List<GameInvite>? gameInvites,
    bool? isLoading,
    String? searchQuery,
    List<Friend>? searchResults,
    String? error,
  }) =>
      FriendsState(
        friends: friends ?? this.friends,
        pendingRequests: pendingRequests ?? this.pendingRequests,
        gameInvites: gameInvites ?? this.gameInvites,
        isLoading: isLoading ?? this.isLoading,
        searchQuery: searchQuery ?? this.searchQuery,
        searchResults: searchResults ?? this.searchResults,
        error: error ?? this.error,
      );
}

// ─── Provider ────────────────────────────────────────────────────────────────

final friendsProvider =
    StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  return FriendsNotifier();
});

class FriendsNotifier extends StateNotifier<FriendsState> {
  FriendsNotifier() : super(const FriendsState());

  Timer? _statusTimer;

  // ── Load / refresh ────────────────────────────────────────────────────────

  void loadMockData() {
    // Hidden until needed for development/debugging
  }



  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchQuery: '', searchResults: []);
      return;
    }
    state = state.copyWith(isLoading: true, searchQuery: query);
    await Future.delayed(const Duration(milliseconds: 600)); // stub network
    // Real: supabase.from('profiles').select().ilike('username', '%$query%').limit(10)
    final results = _mockSearchResults(query);
    state = state.copyWith(isLoading: false, searchResults: results);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '', searchResults: []);
  }

  // ── Friend requests ───────────────────────────────────────────────────────

  Future<bool> sendFriendRequest(String toUserId, String toUsername, String toAvatarEmoji) async {
    // Check not already friends
    if (state.friends.any((f) => f.id == toUserId)) return false;
    if (state.pendingRequests.any((r) => r.fromId == toUserId)) return false;

    // Real: supabase.from('friend_requests').insert({...})
    await Future.delayed(const Duration(milliseconds: 400));

    final request = FriendRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      fromId: toUserId,
      fromUsername: toUsername,
      fromAvatarEmoji: toAvatarEmoji,
      status: FriendRequestStatus.pending,
      sentAt: DateTime.now(),
      isIncoming: false,
    );
    state = state.copyWith(
      pendingRequests: [...state.pendingRequests, request],
      searchResults: state.searchResults
          .map((r) => r.id == toUserId ? r.copyWith(id: r.id) : r)
          .toList(),
    );
    return true;
  }

  Future<void> acceptRequest(String requestId) async {
    // Real: supabase.from('friend_requests').update({'status': 'accepted'}).eq('id', requestId)
    final req = state.pendingRequests.firstWhere((r) => r.id == requestId);
    final newFriend = Friend(
      id: req.fromId,
      username: req.fromUsername,
      avatarEmoji: req.fromAvatarEmoji,
      status: FriendStatus.online,
      level: 1,
      wins: 0,
    );
    state = state.copyWith(
      friends: [...state.friends, newFriend],
      pendingRequests: state.pendingRequests
          .where((r) => r.id != requestId)
          .toList(),
    );
  }

  Future<void> rejectRequest(String requestId) async {
    // Real: supabase.from('friend_requests').update({'status': 'rejected'}).eq('id', requestId)
    state = state.copyWith(
      pendingRequests: state.pendingRequests
          .where((r) => r.id != requestId)
          .toList(),
    );
  }

  Future<void> removeFriend(String friendId) async {
    // Real: supabase.from('friendships').delete().eq('friend_id', friendId)
    state = state.copyWith(
      friends: state.friends.where((f) => f.id != friendId).toList(),
    );
  }

  // ── Game invites ──────────────────────────────────────────────────────────

  Future<bool> sendGameInvite({
    required String toFriendId,
    required String roomCode,
    required String gameMode,
    required String myUsername,
    required String myAvatarEmoji,
  }) async {
    // Real: supabase.from('game_invites').insert({...})
    // + trigger push notification via Supabase Edge Function
    await Future.delayed(const Duration(milliseconds: 300));
    return true; // success
  }

  void acceptGameInvite(String inviteId) {
    state = state.copyWith(
      gameInvites: state.gameInvites
          .where((i) => i.id != inviteId)
          .toList(),
    );
  }

  void dismissGameInvite(String inviteId) {
    state = state.copyWith(
      gameInvites: state.gameInvites
          .where((i) => i.id != inviteId)
          .toList(),
    );
  }

  // ── Mock data ─────────────────────────────────────────────────────────────



  List<Friend> _mockSearchResults(String query) {
    final q = query.toLowerCase();
    final allUsers = [
      const Friend(id: 'u10', username: 'ProLudoPlayer', avatarEmoji: '🎯', status: FriendStatus.online, level: 18, wins: 120),
      const Friend(id: 'u11', username: 'DiceWizard', avatarEmoji: '🧙', status: FriendStatus.offline, level: 6, wins: 28),
      const Friend(id: 'u12', username: 'LudoLegend', avatarEmoji: '🏆', status: FriendStatus.online, level: 45, wins: 312),
      const Friend(id: 'u13', username: 'QuickMove', avatarEmoji: '⚡', status: FriendStatus.inGame, level: 9, wins: 51),
      const Friend(id: 'u14', username: 'NightOwlGamer', avatarEmoji: '🦉', status: FriendStatus.offline, level: 3, wins: 7),
    ];
    return allUsers.where((u) => u.username.toLowerCase().contains(q)).toList();
  }
}
