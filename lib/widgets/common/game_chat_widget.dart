// lib/widgets/common/game_chat_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class GameChatWidget extends StatefulWidget {
  final String currentPlayerName;
  final List<ChatMessage> messages;
  final void Function(String) onSendEmoji;

  const GameChatWidget({
    super.key,
    required this.currentPlayerName,
    required this.messages,
    required this.onSendEmoji,
  });

  @override
  State<GameChatWidget> createState() => _GameChatWidgetState();
}

class _GameChatWidgetState extends State<GameChatWidget> {
  bool _showEmojiPicker = false;

  static const _quickEmojis = [
    '😂', '😮', '😡', '🎉', '👍', '👎',
    '🔥', '😎', '😢', '🎲', '✂️', '🏆',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Message bubbles
        if (widget.messages.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: ListView.builder(
              reverse: true,
              shrinkWrap: true,
              itemCount: widget.messages.length,
              itemBuilder: (context, i) {
                final msg = widget.messages[
                    widget.messages.length - 1 - i];
                return _MessageBubble(message: msg);
              },
            ),
          ),

        const SizedBox(height: 6),

        // Emoji quick-send button
        GestureDetector(
          onTap: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('😊', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text('React',
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ),

        // Emoji picker
        if (_showEmojiPicker)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    widget.onSendEmoji(emoji);
                    setState(() => _showEmojiPicker = false);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.darkBg,
                    ),
                    child: Center(
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class ChatMessage {
  final String playerName;
  final String content;
  final bool isEmoji;
  final DateTime timestamp;

  ChatMessage({
    required this.playerName,
    required this.content,
    this.isEmoji = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: message.isEmoji
                ? const EdgeInsets.all(4)
                : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.3)),
            ),
            child: message.isEmoji
                ? Text(message.content,
                    style: const TextStyle(fontSize: 22))
                : RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${message.playerName}: ',
                          style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: message.content,
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
