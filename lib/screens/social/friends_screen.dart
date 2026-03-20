// lib/screens/social/friends_screen.dart
//
// Full friend management screen:
//  - Tab 1: Friend list with online/in-game/offline sections
//  - Tab 2: Search users by username + send friend request
//  - Incoming friend requests banner
//  - Game invite banner (accept → navigate to room)
//  - Invite friend to your active room

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/friends_provider.dart';
import '../../services/supabase_service.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  /// If non-null, user arrived here from an active room to invite friends
  final String? activeRoomCode;
  final String? activeGameMode;

  const FriendsScreen({
    super.key,
    this.activeRoomCode,
    this.activeGameMode,
  });

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchController = TextEditingController();
  bool _inviteMode = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _inviteMode = widget.activeRoomCode != null;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: _buildAppBar(state),
      body: Column(
        children: [
          // ── Game invite banners ──────────────────────────────────
          if (state.gameInvites.isNotEmpty)
            ...state.gameInvites.map((inv) => _GameInviteBanner(invite: inv)),
          // ── Incoming request banner ──────────────────────────────
          if (state.incoming.isNotEmpty)
            _RequestsBanner(requests: state.incoming),
          // ── Tabs ─────────────────────────────────────────────────
          Container(
            color: AppColors.darkSurface,
            child: TabBar(
              controller: _tabs,
              labelStyle: GoogleFonts.fredoka(fontSize: 14),
              unselectedLabelStyle: GoogleFonts.fredoka(fontSize: 13),
              labelColor: AppColors.primaryLight,
              unselectedLabelColor: Colors.white38,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('👥 Friends'),
                    if (state.totalBadgeCount > 0) ...[
                      const SizedBox(width: 6),
                      _Badge(count: state.totalBadgeCount),
                    ],
                  ]),
                ),
                const Tab(text: '🔍 Find Players'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _FriendsTab(inviteMode: _inviteMode, activeRoomCode: widget.activeRoomCode, activeGameMode: widget.activeGameMode),
                _SearchTab(searchController: _searchController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(FriendsState state) {
    return AppBar(
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Text(
        _inviteMode ? '📨 Invite Friends' : '👥 Friends',
        style: GoogleFonts.fredoka(color: Colors.white, fontSize: 20),
      ),
      actions: [
        if (_inviteMode)
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Done', style: GoogleFonts.nunito(color: AppColors.primaryLight)),
          )
        else
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Colors.white54),
            onPressed: () => _tabs.animateTo(1),
          ),
      ],
    );
  }
}

// ─── Friends tab ─────────────────────────────────────────────────────────────

class _FriendsTab extends ConsumerWidget {
  final bool inviteMode;
  final String? activeRoomCode;
  final String? activeGameMode;

  const _FriendsTab({
    required this.inviteMode,
    this.activeRoomCode,
    this.activeGameMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsProvider);

    if (state.friends.isEmpty) {
      return _EmptyFriends();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Online / in-game friends
        if (state.onlineFriends.isNotEmpty) ...[
          _SectionHeader(
            label: '🟢 Online',
            count: state.onlineFriends.length,
          ),
          ...state.onlineFriends.map((f) => _FriendTile(
                friend: f,
                inviteMode: inviteMode,
                activeRoomCode: activeRoomCode,
                activeGameMode: activeGameMode,
              )),
        ],
        // Offline friends
        if (state.offlineFriends.isNotEmpty) ...[
          _SectionHeader(
            label: '⚫ Offline',
            count: state.offlineFriends.length,
          ),
          ...state.offlineFriends.map((f) => _FriendTile(
                friend: f,
                inviteMode: inviteMode,
                activeRoomCode: activeRoomCode,
                activeGameMode: activeGameMode,
              )),
        ],
        // Outgoing requests
        if (state.outgoing.isNotEmpty) ...[
          _SectionHeader(label: '📤 Sent Requests', count: state.outgoing.length),
          ...state.outgoing.map((r) => _OutgoingRequestTile(request: r)),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}

// ─── Friend tile ─────────────────────────────────────────────────────────────

class _FriendTile extends ConsumerWidget {
  final Friend friend;
  final bool inviteMode;
  final String? activeRoomCode;
  final String? activeGameMode;

  const _FriendTile({
    required this.friend,
    required this.inviteMode,
    this.activeRoomCode,
    this.activeGameMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(friend.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error.withValues(alpha: 0.8),
        child: const Icon(Icons.person_remove_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmRemove(context),
      onDismissed: (_) => ref.read(friendsProvider.notifier).removeFriend(friend.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.darkBg,
                  border: Border.all(color: friend.statusColor.withValues(alpha: 0.5), width: 2),
                ),
                child: Center(
                  child: Text(friend.avatarEmoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: friend.statusColor,
                    border: Border.all(color: AppColors.darkCard, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            friend.username,
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 15),
          ),
          subtitle: Row(
            children: [
              Text(
                friend.statusLabel,
                style: GoogleFonts.nunito(fontSize: 11, color: friend.statusColor),
              ),
              const SizedBox(width: 8),
              Text(
                'Lv.${friend.level}  •  ${friend.wins}W',
                style: GoogleFonts.nunito(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
          trailing: inviteMode
              ? _InviteButton(friend: friend, roomCode: activeRoomCode!, gameMode: activeGameMode ?? 'classic')
              : friend.status == FriendStatus.inGame && friend.currentRoomCode != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _JoinButton(roomCode: friend.currentRoomCode!),
                        const SizedBox(width: 6),
                        _WatchButton(roomCode: friend.currentRoomCode!),
                      ],
                    )
                  : const SizedBox(width: 8),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.05);
  }

  Future<bool> _confirmRemove(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: Text('Remove Friend?',
            style: GoogleFonts.fredoka(color: Colors.white)),
        content: Text(
          'Remove ${friend.username} from your friends list?',
          style: GoogleFonts.nunito(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.nunito(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: GoogleFonts.nunito(color: AppColors.error)),
          ),
        ],
      ),
    ) ?? false;
  }
}

// ─── Invite button (invite mode) ─────────────────────────────────────────────

class _InviteButton extends ConsumerStatefulWidget {
  final Friend friend;
  final String roomCode;
  final String gameMode;
  const _InviteButton({required this.friend, required this.roomCode, required this.gameMode});

  @override
  ConsumerState<_InviteButton> createState() => _InviteButtonState();
}

class _InviteButtonState extends ConsumerState<_InviteButton> {
  bool _sent = false;
  bool _sending = false;

  Future<void> _send() async {
    if (_sent || _sending) return;
    setState(() => _sending = true);
    final svc = ref.read(supabaseServiceProvider);
    final ok = await ref.read(friendsProvider.notifier).sendGameInvite(
      toFriendId: widget.friend.id,
      roomCode: widget.roomCode,
      gameMode: widget.gameMode,
      myUsername: svc.currentUserId ?? 'Player',
      myAvatarEmoji: '🎮',
    );
    if (mounted) setState(() { _sending = false; _sent = ok; });
    if (ok) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 200.ms,
      child: ElevatedButton(
        onPressed: _sent ? null : _send,
        style: ElevatedButton.styleFrom(
          backgroundColor: _sent ? Colors.white10 : AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(80, 34),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: _sending
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                _sent ? '✓ Sent' : '📨 Invite',
                style: GoogleFonts.fredoka(fontSize: 13),
              ),
      ),
    );
  }
}

// ─── Watch button (spectate friend's game) ───────────────────────────────────

class _WatchButton extends StatelessWidget {
  final String roomCode;
  const _WatchButton({required this.roomCode});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/spectate', extra: {'roomCode': roomCode});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Text('👀', style: GoogleFonts.nunito(fontSize: 15)),
      ),
    );
  }
}

// ─── Join button (friend in-game) ─────────────────────────────────────────────

class _JoinButton extends StatelessWidget {
  final String roomCode;
  const _JoinButton({required this.roomCode});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        context.push('/online/lobby', extra: {'isHost': false, 'code': roomCode});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF9800).withValues(alpha: 0.2),
        foregroundColor: const Color(0xFFFF9800),
        minimumSize: const Size(70, 34),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFFF9800), width: 1),
        ),
        elevation: 0,
      ),
      child: Text('Join', style: GoogleFonts.fredoka(fontSize: 13)),
    );
  }
}

// ─── Outgoing request tile ────────────────────────────────────────────────────

class _OutgoingRequestTile extends ConsumerWidget {
  final FriendRequest request;
  const _OutgoingRequestTile({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Text(request.fromAvatarEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(request.fromUsername,
                  style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 14)),
              Text('Request pending...',
                  style: GoogleFonts.nunito(fontSize: 11, color: Colors.white38)),
            ]),
          ),
          GestureDetector(
            onTap: () => ref.read(friendsProvider.notifier).rejectRequest(request.id),
            child: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── Search tab ───────────────────────────────────────────────────────────────

class _SearchTab extends ConsumerWidget {
  final TextEditingController searchController;
  const _SearchTab({required this.searchController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: TextField(
              controller: searchController,
              style: GoogleFonts.nunito(color: Colors.white),
              onChanged: (q) => ref.read(friendsProvider.notifier).searchUsers(q),
              decoration: InputDecoration(
                hintText: 'Search by username...',
                hintStyle: GoogleFonts.nunito(color: Colors.white38),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white38, size: 18),
                        onPressed: () {
                          searchController.clear();
                          ref.read(friendsProvider.notifier).clearSearch();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        // Results
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.searchResults.isEmpty && (state.searchQuery ?? '').isEmpty
                  ? _SearchHint()
                  : state.searchResults.isEmpty
                      ? Center(
                          child: Text('No players found',
                              style: GoogleFonts.nunito(color: Colors.white38)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: state.searchResults.length,
                          itemBuilder: (ctx, i) => _SearchResultTile(
                            user: state.searchResults[i],
                            alreadyFriend: state.friends.any((f) => f.id == state.searchResults[i].id),
                            pendingOutgoing: state.outgoing.any((r) => r.fromId == state.searchResults[i].id),
                          ).animate(delay: (i * 40).ms).fadeIn().slideY(begin: 0.1),
                        ),
        ),
      ],
    );
  }
}

// ─── Search result tile ───────────────────────────────────────────────────────

class _SearchResultTile extends ConsumerStatefulWidget {
  final Friend user;
  final bool alreadyFriend;
  final bool pendingOutgoing;
  const _SearchResultTile({required this.user, required this.alreadyFriend, required this.pendingOutgoing});

  @override
  ConsumerState<_SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends ConsumerState<_SearchResultTile> {
  bool _sent = false;
  bool _sending = false;

  Future<void> _sendRequest() async {
    setState(() => _sending = true);
    final ok = await ref.read(friendsProvider.notifier).sendFriendRequest(
      widget.user.id, widget.user.username, widget.user.avatarEmoji,
    );
    if (mounted) setState(() { _sending = false; _sent = ok; });
    if (ok) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isFriend = widget.alreadyFriend;
    final isPending = widget.pendingOutgoing || _sent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkBg,
              border: Border.all(color: widget.user.statusColor.withValues(alpha: 0.4)),
            ),
            child: Center(child: Text(widget.user.avatarEmoji, style: const TextStyle(fontSize: 20))),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: 11, height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.user.statusColor,
                border: Border.all(color: AppColors.darkCard, width: 1.5),
              ),
            ),
          ),
        ]),
        title: Text(widget.user.username,
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 14)),
        subtitle: Text(
          'Lv.${widget.user.level}  •  ${widget.user.wins}W  •  ${widget.user.statusLabel}',
          style: GoogleFonts.nunito(fontSize: 11, color: Colors.white38),
        ),
        trailing: isFriend
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenPlayer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.greenPlayer.withValues(alpha: 0.3)),
                ),
                child: Text('Friends', style: GoogleFonts.nunito(fontSize: 11, color: AppColors.greenPlayer)),
              )
            : ElevatedButton(
                onPressed: isPending || _sending ? null : _sendRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPending ? Colors.white10 : AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _sending
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isPending ? '✓ Sent' : '+ Add',
                        style: GoogleFonts.fredoka(fontSize: 12)),
              ),
      ),
    );
  }
}

// ─── Requests banner ──────────────────────────────────────────────────────────

class _RequestsBanner extends ConsumerWidget {
  final List<FriendRequest> requests;
  const _RequestsBanner({required this.requests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('📬', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('${requests.length} Friend Request${requests.length > 1 ? 's' : ''}',
                style: GoogleFonts.fredoka(color: AppColors.primaryLight, fontSize: 14)),
          ]),
          const SizedBox(height: 8),
          ...requests.map((r) => _RequestRow(request: r)),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }
}

class _RequestRow extends ConsumerWidget {
  final FriendRequest request;
  const _RequestRow({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(request.fromAvatarEmoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(request.fromUsername,
                style: GoogleFonts.nunito(color: Colors.white, fontSize: 13)),
          ),
          // Accept
          _ActionBtn(
            label: '✓',
            color: AppColors.greenPlayer,
            onTap: () => ref.read(friendsProvider.notifier).acceptRequest(request.id),
          ),
          const SizedBox(width: 6),
          // Decline
          _ActionBtn(
            label: '✕',
            color: AppColors.error,
            onTap: () => ref.read(friendsProvider.notifier).rejectRequest(request.id),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Center(child: Text(label, style: TextStyle(color: color, fontSize: 14))),
      ),
    );
  }
}

// ─── Game invite banner ───────────────────────────────────────────────────────

class _GameInviteBanner extends ConsumerWidget {
  final GameInvite invite;
  const _GameInviteBanner({required this.invite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text(invite.fromAvatarEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${invite.fromUsername} invited you!',
                style: GoogleFonts.fredoka(color: Colors.white, fontSize: 14),
              ),
              Text(
                '🎮 ${invite.gameMode.toUpperCase()} • Room ${invite.roomCode}',
                style: GoogleFonts.nunito(fontSize: 11, color: Colors.white54),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(friendsProvider.notifier).acceptGameInvite(invite.id);
              context.push('/online/lobby', extra: {
                'isHost': false,
                'code': invite.roomCode,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(64, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Join', style: GoogleFonts.fredoka(fontSize: 13)),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => ref.read(friendsProvider.notifier).dismissGameInvite(invite.id),
            child: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        Text(label,
            style: GoogleFonts.fredoka(
                color: Colors.white54, fontSize: 12, letterSpacing: 0.5)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$count', style: GoogleFonts.nunito(fontSize: 10, color: Colors.white38)),
        ),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18, height: 18,
      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
      child: Center(
        child: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _EmptyFriends extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👥', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No friends yet', style: GoogleFonts.fredoka(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 6),
          Text('Search for players to add them!',
              style: GoogleFonts.nunito(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Find Players', style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 6),
          Text('Search by username to add friends',
              style: GoogleFonts.nunito(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}
