// lib/widgets/common/game_chat_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/chat_provider.dart';

const _emojiRows = [
  ['😂', '😮', '😡', '🥹', '😎', '🤩'],
  ['👍', '👎', '🙏', '✂️', '🔥', '💀'],
  ['🎲', '🏆', '🎉', '😤', '💪', '🤫'],
  ['⚡', '🌟', '💎', '🐉', '🤖', '🥊'],
];

// ── Chat FAB ────────────────────────────────────────────────────────────────

class ChatFab extends ConsumerWidget {
  const ChatFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(chatProvider).unreadCount;
    final isOpen = ref.watch(chatProvider).isOpen;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(chatProvider.notifier).toggleChat();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOpen ? AppColors.primary : AppColors.darkCard,
              border: Border.all(
                color: isOpen ? AppColors.primaryLight : AppColors.darkBorder,
                width: 1.5,
              ),
              boxShadow: isOpen
                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12)]
                  : null,
            ),
            child: Center(
              child: Text(isOpen ? '✕' : '💬',
                  style: TextStyle(fontSize: isOpen ? 16 : 20)),
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
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ).animate().scale(curve: Curves.elasticOut),
            ),
        ],
      ),
    );
  }
}

// ── Chat Panel ──────────────────────────────────────────────────────────────

class GameChatPanel extends ConsumerStatefulWidget {
  final String localPlayerName;
  final int localPlayerIndex;

  const GameChatPanel({
    super.key,
    required this.localPlayerName,
    required this.localPlayerIndex,
  });

  @override
  ConsumerState<GameChatPanel> createState() => _GameChatPanelState();
}

class _GameChatPanelState extends ConsumerState<GameChatPanel>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    ref.read(chatProvider.notifier).sendText(
          playerName: widget.localPlayerName,
          playerIndex: widget.localPlayerIndex,
          text: text,
        );
    _textController.clear();
    _scrollToBottom();
  }

  void _sendEmoji(String emoji) {
    HapticFeedback.lightImpact();
    ref.read(chatProvider.notifier).sendEmoji(
          playerName: widget.localPlayerName,
          playerIndex: widget.localPlayerIndex,
          emoji: emoji,
        );
    setState(() => _showEmoji = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider).messages;

    ref.listen(chatProvider, (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) _scrollToBottom();
    });

    return SlideTransition(
      position: _slideAnim,
      child: Container(
        height: 340,
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.darkBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessageList(messages)),
            if (_showEmoji) _buildEmojiGrid(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: AppColors.darkBorder)),
      ),
      child: Row(
        children: [
          const Spacer(),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.darkBorder, borderRadius: BorderRadius.circular(2))),
          const Spacer(),
          Text('💬 Chat', style: GoogleFonts.fredoka(fontSize: 15, color: Colors.white70)),
          const Spacer(),
          GestureDetector(
            onTap: () => ref.read(chatProvider.notifier).closeChat(),
            child: const Icon(Icons.expand_more_rounded, color: Colors.white54, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💬', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text('No messages yet', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMuted)),
            Text('Say hello! 👋', style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, i) => _ChatBubble(
        message: messages[i],
        isSelf: messages[i].isSelf,
      ).animate().fadeIn(duration: const Duration(milliseconds: 150)),
    );
  }

  Widget _buildEmojiGrid() {
    return Container(
      color: AppColors.darkCard,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _emojiRows.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((emoji) => GestureDetector(
              onTap: () => _sendEmoji(emoji),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.darkBg),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
            )).toList(),
          ),
        )).toList(),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 150)).slideY(begin: 0.1);
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showEmoji = !_showEmoji),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _showEmoji ? AppColors.primary.withOpacity(0.3) : AppColors.darkBg,
                border: Border.all(color: _showEmoji ? AppColors.primary : AppColors.darkBorder),
              ),
              child: const Center(child: Text('😊', style: TextStyle(fontSize: 18))),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.darkBg,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: TextField(
                controller: _textController,
                style: GoogleFonts.nunito(color: Colors.white, fontSize: 13),
                maxLength: 120,
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendText(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.nunito(color: Colors.white38, fontSize: 13),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendText,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 8)],
              ),
              child: const Center(child: Icon(Icons.send_rounded, color: Colors.white, size: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat Bubble ─────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isSelf;
  const _ChatBubble({required this.message, required this.isSelf});

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) return _buildSystem();
    if (message.isEmoji) return _buildEmoji();
    return _buildText();
  }

  Widget _buildSystem() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(message.content,
              style: GoogleFonts.nunito(fontSize: 10, color: Colors.white38)),
        ),
      ),
    );
  }

  Widget _buildEmoji() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isSelf) _Dot(color: message.playerColor),
          if (!isSelf) const SizedBox(width: 6),
          Column(
            crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isSelf)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 2),
                  child: Text(message.playerName,
                      style: GoogleFonts.nunito(fontSize: 9, color: message.playerColor, fontWeight: FontWeight.bold)),
                ),
              Text(message.content, style: const TextStyle(fontSize: 28)),
            ],
          ),
          if (isSelf) const SizedBox(width: 6),
          if (isSelf) _Dot(color: message.playerColor),
        ],
      ),
    );
  }

  Widget _buildText() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSelf) _Dot(color: message.playerColor),
          if (!isSelf) const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isSelf)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(message.playerName,
                        style: GoogleFonts.nunito(fontSize: 9, color: message.playerColor, fontWeight: FontWeight.bold)),
                  ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelf ? AppColors.primary.withOpacity(0.85) : AppColors.darkCard,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isSelf ? 14 : 4),
                      bottomRight: Radius.circular(isSelf ? 4 : 14),
                    ),
                    border: isSelf ? null : Border.all(color: message.playerColor.withOpacity(0.3)),
                  ),
                  child: Text(message.content, style: GoogleFonts.nunito(fontSize: 13, color: Colors.white)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(_fmt(message.timestamp),
                      style: GoogleFonts.nunito(fontSize: 9, color: Colors.white24)),
                ),
              ],
            ),
          ),
          if (isSelf) const SizedBox(width: 6),
          if (isSelf) _Dot(color: message.playerColor),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 20, height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.25),
          border: Border.all(color: color, width: 1.5),
        ),
      );
}
