// lib/screens/social/spectator_screen.dart
//
// Spectator Mode screen — read-only live view of an ongoing game.
//
// Layout:
//   Top bar   — room code, player turn indicator, spectator count badge
//   Board     — read-only LudoBoardWidget (no tap handlers for spectators)
//   Player strip — live token-progress bars for each player
//   Event log — live scrolling game events
//   Chat FAB  — spectator-only chat (separate from player chat)
//   Chat panel — slide-up spectator chat with emoji + text

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/game_models.dart';
import '../../providers/spectator_provider.dart';
import '../../widgets/board/ludo_board_widget.dart';
import '../../widgets/common/event_log_widget.dart';

class SpectatorScreen extends ConsumerStatefulWidget {
  final String roomCode;
  final String? myUsername;
  final String? myAvatarEmoji;
  final String? myId;

  const SpectatorScreen({
    super.key,
    required this.roomCode,
    this.myUsername,
    this.myAvatarEmoji,
    this.myId,
  });

  @override
  ConsumerState<SpectatorScreen> createState() => _SpectatorScreenState();
}

class _SpectatorScreenState extends ConsumerState<SpectatorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spectatorProvider.notifier).joinRoom(
            roomCode: widget.roomCode,
            myUsername: widget.myUsername ?? 'Spectator',
            myAvatarEmoji: widget.myAvatarEmoji ?? '👀',
            myId: widget.myId ?? 'local_spectator',
          );
    });
  }

  @override
  void dispose() {
    ref.read(spectatorProvider.notifier).leaveRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(spectatorProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: switch (state.connectionStatus) {
          SpectatorConnectionStatus.connecting => _buildConnecting(),
          SpectatorConnectionStatus.error => _buildError(state.errorMessage),
          _ => _buildLiveView(state),
        },
      ),
    );
  }

  // ── Connecting overlay ───────────────────────────────────────────────────

  Widget _buildConnecting() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Joining as spectator...',
              style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Room ${widget.roomCode}',
              style: GoogleFonts.nunito(
                  color: AppColors.textMuted, fontSize: 14, letterSpacing: 2)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildError(String? msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('❌', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(msg ?? 'Could not join spectator view',
              style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  // ── Main live view ───────────────────────────────────────────────────────

  Widget _buildLiveView(SpectatorState state) {
    final gameState = state.gameState;

    return Stack(
      children: [
        Column(
          children: [
            _buildTopBar(state),
            if (gameState != null) _buildPlayerStrip(gameState),
            const SizedBox(height: 4),
            if (gameState != null && gameState.eventLog.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: EventLogWidget(events: gameState.eventLog),
              ),
            const SizedBox(height: 4),
            Expanded(
              child: gameState != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Stack(
                        children: [
                          // Read-only board (spectator can't tap tokens)
                          AbsorbPointer(
                            child: LudoBoardWidget(gameState: gameState),
                          ),
                          // "SPECTATING" watermark
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '👀 SPECTATING',
                                style: GoogleFonts.fredoka(
                                    fontSize: 11,
                                    color: Colors.white38,
                                    letterSpacing: 1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            _buildSpectatorStrip(state),
          ],
        ),
        // Chat FAB + panel
        _SpectatorChatLayer(
          myUsername: widget.myUsername ?? 'Spectator',
          myAvatarEmoji: widget.myAvatarEmoji ?? '👀',
        ),
      ],
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar(SpectatorState state) {
    final gameState = state.gameState;
    final currentPlayer = gameState != null &&
            gameState.currentPlayerIndex < gameState.players.length
        ? gameState.players[gameState.currentPlayerIndex]
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              ref.read(spectatorProvider.notifier).leaveRoom();
              context.pop();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.darkCard,
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white54, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          // Room code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Text(
              '📡 ${state.roomCode}',
              style: GoogleFonts.fredoka(fontSize: 13, color: Colors.white70),
            ),
          ),
          const SizedBox(width: 8),
          // Current turn indicator
          if (currentPlayer != null)
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: currentPlayer.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: currentPlayer.color.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currentPlayer.avatarEmoji,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        currentPlayer.name,
                        style: GoogleFonts.fredoka(
                            fontSize: 12, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('🎲',
                        style: GoogleFonts.fredoka(
                            fontSize: 12, color: Colors.white38)),
                  ],
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 8),
          // Spectator count
          _SpectatorCountBadge(count: state.spectatorCount),
        ],
      ),
    );
  }

  // ── Player strip ──────────────────────────────────────────────────────────

  Widget _buildPlayerStrip(GameState gameState) {
    return SizedBox(
      height: 58,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: gameState.players.length,
        itemBuilder: (ctx, i) {
          final player = gameState.players[i];
          final isCurrent = i == gameState.currentPlayerIndex;
          final finished = player.finishedTokenCount;

          return AnimatedContainer(
            duration: 250.ms,
            margin: const EdgeInsets.only(right: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color:
                  isCurrent ? player.color.withOpacity(0.2) : AppColors.darkCard,
              border: Border.all(
                color: isCurrent ? player.color : AppColors.darkBorder,
                width: isCurrent ? 2 : 1,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                          color: player.color.withOpacity(0.3),
                          blurRadius: 8)
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(player.avatarEmoji,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.name,
                        style: GoogleFonts.fredoka(
                            fontSize: 11, color: Colors.white70)),
                    Row(
                      children: List.generate(4, (t) {
                        final tok = player.tokens[t];
                        return Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tok.isFinished
                                ? player.color
                                : tok.isAtHome
                                    ? Colors.white12
                                    : player.color.withOpacity(0.55),
                          ),
                        );
                      }),
                    ),
                    Text(
                      '$finished/4 home',
                      style: GoogleFonts.nunito(
                          fontSize: 9, color: Colors.white38),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Spectator strip ───────────────────────────────────────────────────────

  Widget _buildSpectatorStrip(SpectatorState state) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Text('👀',
              style: GoogleFonts.nunito(
                  fontSize: 12, color: Colors.white38)),
          const SizedBox(width: 6),
          Text(
            '${state.spectatorCount} watching',
            style: GoogleFonts.nunito(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.spectators.length,
              itemBuilder: (ctx, i) {
                final s = state.spectators[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: s.username,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.darkCard,
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Center(
                        child: Text(s.avatarEmoji,
                            style: const TextStyle(fontSize: 15)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Spectator count badge ─────────────────────────────────────────────────────

class _SpectatorCountBadge extends StatelessWidget {
  final int count;
  const _SpectatorCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👀', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: GoogleFonts.fredoka(fontSize: 13, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

// ── Spectator chat layer (FAB + slide-up panel) ───────────────────────────────

class _SpectatorChatLayer extends ConsumerWidget {
  final String myUsername;
  final String myAvatarEmoji;

  const _SpectatorChatLayer({
    required this.myUsername,
    required this.myAvatarEmoji,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(spectatorProvider);

    return Positioned(
      bottom: 46, // above spectator strip
      right: 12,
      left: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Chat panel
          if (state.chatOpen)
            _SpectatorChatPanel(
              myUsername: myUsername,
              myAvatarEmoji: myAvatarEmoji,
            ).animate().slideY(begin: 0.3, curve: Curves.easeOutCubic),
          const SizedBox(height: 8),
          // FAB
          Padding(
            padding: const EdgeInsets.only(right: 0),
            child: _SpectatorChatFab(unread: state.unreadChat),
          ),
        ],
      ),
    );
  }
}

class _SpectatorChatFab extends ConsumerWidget {
  final int unread;
  const _SpectatorChatFab({required this.unread});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(spectatorProvider).chatOpen;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(spectatorProvider.notifier).toggleChat();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: 200.ms,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOpen ? AppColors.primary : AppColors.darkCard,
              border: Border.all(
                  color: isOpen ? AppColors.primaryLight : AppColors.darkBorder,
                  width: 1.5),
              boxShadow: isOpen
                  ? [BoxShadow(
                      color: AppColors.primary.withOpacity(0.4), blurRadius: 12)]
                  : null,
            ),
            child: Center(
              child: Text(isOpen ? '✕' : '💬',
                  style: TextStyle(fontSize: isOpen ? 14 : 18)),
            ),
          ),
          if (unread > 0 && !isOpen)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.redPlayer,
                  border: Border.all(color: AppColors.darkBg, width: 1.5),
                ),
                child: Center(
                  child: Text('$unread',
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ).animate().scale(curve: Curves.elasticOut),
            ),
        ],
      ),
    );
  }
}

// ── Spectator chat panel ───────────────────────────────────────────────────────

class _SpectatorChatPanel extends ConsumerStatefulWidget {
  final String myUsername;
  final String myAvatarEmoji;
  const _SpectatorChatPanel(
      {required this.myUsername, required this.myAvatarEmoji});

  @override
  ConsumerState<_SpectatorChatPanel> createState() =>
      _SpectatorChatPanelState();
}

class _SpectatorChatPanelState extends ConsumerState<_SpectatorChatPanel> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showEmoji = false;

  static const _emojis = [
    '😂', '😮', '🔥', '👍', '👎', '🎲',
    '🏆', '😎', '💀', '🎉', '😤', '👀',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: 200.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    ref.read(spectatorProvider.notifier).sendText(
          username: widget.myUsername,
          avatarEmoji: widget.myAvatarEmoji,
          text: text,
        );
    _textController.clear();
    _scrollToBottom();
  }

  void _sendEmoji(String emoji) {
    HapticFeedback.lightImpact();
    ref.read(spectatorProvider.notifier).sendEmoji(
          username: widget.myUsername,
          avatarEmoji: widget.myAvatarEmoji,
          emoji: emoji,
        );
    setState(() => _showEmoji = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(spectatorProvider).chatMessages;

    ref.listen(spectatorProvider, (prev, next) {
      if ((prev?.chatMessages.length ?? 0) < next.chatMessages.length) {
        _scrollToBottom();
      }
    });

    return Container(
      height: 300,
      margin: const EdgeInsets.only(right: 0),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border.all(color: AppColors.darkBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              border:
                  Border(bottom: BorderSide(color: AppColors.darkBorder)),
            ),
            child: Row(
              children: [
                const Spacer(),
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.darkBorder,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const Spacer(),
                Text('👀 Spectator Chat',
                    style: GoogleFonts.fredoka(
                        fontSize: 13, color: Colors.white54)),
                const Spacer(),
                GestureDetector(
                  onTap: () =>
                      ref.read(spectatorProvider.notifier).closeChat(),
                  child: const Icon(Icons.expand_more_rounded,
                      color: Colors.white38, size: 20),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text('No spectator messages yet',
                        style: GoogleFonts.nunito(
                            fontSize: 12, color: AppColors.textMuted)),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) =>
                        _SpectatorBubble(msg: messages[i])
                            .animate()
                            .fadeIn(duration: 150.ms),
                  ),
          ),
          // Emoji row (conditional)
          if (_showEmoji)
            Container(
              color: AppColors.darkCard,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              child: Wrap(
                spacing: 8,
                children: _emojis
                    .map((e) => GestureDetector(
                          onTap: () => _sendEmoji(e),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.darkBg),
                            child: Center(
                                child: Text(e,
                                    style:
                                        const TextStyle(fontSize: 20))),
                          ),
                        ))
                    .toList(),
              ),
            ).animate().fadeIn(duration: 120.ms),
          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              border:
                  Border(top: BorderSide(color: AppColors.darkBorder)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      setState(() => _showEmoji = !_showEmoji),
                  child: AnimatedContainer(
                    duration: 150.ms,
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _showEmoji
                          ? AppColors.primary.withOpacity(0.3)
                          : AppColors.darkBg,
                      border: Border.all(
                          color: _showEmoji
                              ? AppColors.primary
                              : AppColors.darkBorder),
                    ),
                    child: const Center(
                        child: Text('😊',
                            style: TextStyle(fontSize: 16))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.darkBg,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: AppColors.darkBorder),
                    ),
                    child: TextField(
                      controller: _textController,
                      style: GoogleFonts.nunito(
                          color: Colors.white, fontSize: 13),
                      maxLength: 120,
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                      decoration: InputDecoration(
                        hintText: 'Spectator chat...',
                        hintStyle: GoogleFonts.nunito(
                            color: Colors.white38, fontSize: 13),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendText,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 8)
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.send_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpectatorBubble extends StatelessWidget {
  final SpectatorChatMessage msg;
  const _SpectatorBubble({required this.msg});

  bool get _isSystem => msg.username == 'System';

  @override
  Widget build(BuildContext context) {
    if (_isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(msg.content,
                style: GoogleFonts.nunito(
                    fontSize: 10, color: Colors.white38)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: msg.isSelf
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isSelf) ...[
            Text(msg.avatarEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
          ],
          if (msg.isEmoji)
            Text(msg.content, style: const TextStyle(fontSize: 26))
          else
            Flexible(
              child: Column(
                crossAxisAlignment: msg.isSelf
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!msg.isSelf)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(msg.username,
                          style: GoogleFonts.nunito(
                              fontSize: 9,
                              color: Colors.white54,
                              fontWeight: FontWeight.bold)),
                    ),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: msg.isSelf
                          ? AppColors.primary.withOpacity(0.8)
                          : AppColors.darkCard,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft:
                            Radius.circular(msg.isSelf ? 12 : 3),
                        bottomRight:
                            Radius.circular(msg.isSelf ? 3 : 12),
                      ),
                      border: msg.isSelf
                          ? null
                          : Border.all(color: Colors.white12),
                    ),
                    child: Text(msg.content,
                        style: GoogleFonts.nunito(
                            fontSize: 12, color: Colors.white)),
                  ),
                ],
              ),
            ),
          if (msg.isSelf) ...[
            const SizedBox(width: 6),
            Text(msg.avatarEmoji, style: const TextStyle(fontSize: 18)),
          ],
        ],
      ),
    );
  }
}
