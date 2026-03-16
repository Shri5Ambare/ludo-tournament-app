// lib/screens/online/online_lobby_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/game_models.dart';
import '../../providers/chat_provider.dart';
import '../../services/supabase_service.dart';

class OnlineLobbyScreen extends ConsumerStatefulWidget {
  final bool isHost;
  final String? joinCode;
  const OnlineLobbyScreen({super.key, required this.isHost, this.joinCode});

  @override
  ConsumerState<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends ConsumerState<OnlineLobbyScreen> {
  final _codeController = TextEditingController();
  OnlineRoom? _room;
  String _statusMsg = '';
  bool _isLoading = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isHost) {
        _createRoom();
      } else if (widget.joinCode != null) {
        _codeController.text = widget.joinCode!;
        _joinRoom();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() { _isLoading = true; _statusMsg = 'Creating room...'; });
    final svc = ref.read(supabaseServiceProvider);
    final room = await svc.createRoom(
      gameMode: GameMode.classic,
      turnTimer: 30,
      maxPlayers: 4,
    );
    setState(() {
      _isLoading = false;
      _room = room;
      _statusMsg = room != null
          ? 'Share code with friends!'
          : '❌ Failed to create room';
    });
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _statusMsg = '⚠️ Enter a 6-character room code');
      return;
    }
    setState(() { _isLoading = true; _statusMsg = 'Joining room $code...'; });
    final svc = ref.read(supabaseServiceProvider);
    final room = await svc.joinRoom(code);
    setState(() {
      _isLoading = false;
      _room = room;
      _statusMsg = room != null ? 'Joined! Waiting for host...' : '❌ Room not found';
    });
  }

  void _startGame() {
    if (_room == null) return;
    final svc = ref.read(supabaseServiceProvider);
    final configs = _room!.players.map((p) => {
      'name': p.name,
      'type': PlayerType.human,
      'avatar': '🎮',
    }).toList();

    // Determine local player index from the current user
    final localIndex = _room!.players
        .indexWhere((p) => p.id == svc.currentUserId);
    final safeLocalIndex = localIndex < 0 ? 0 : localIndex;
    final localName = configs[safeLocalIndex]['name'] as String? ?? 'Player';

    // Wire incoming chat from Supabase Realtime → ChatNotifier
    svc.onChatEvent = (json) =>
        ref.read(chatProvider.notifier).receiveFromJson(json);

    // Wire outgoing chat from ChatNotifier → Supabase broadcast
    ref.read(chatProvider.notifier).onSend = (chatMsg) {
      svc.broadcastChat(
        playerName: chatMsg.playerName,
        playerIndex: chatMsg.playerIndex,
        content: chatMsg.content,
        type: chatMsg.type.name,
        messageId: chatMsg.id,
        timestamp: chatMsg.timestamp.toIso8601String(),
      );
    };

    context.pushReplacement('/game', extra: {
      'playerConfigs': configs,
      'gameMode': _room!.gameMode,
      'turnTimerSeconds': _room!.turnTimer,
      'localPlayerName': localName,
      'localPlayerIndex': safeLocalIndex,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.isHost ? '🌐 Host Online Game' : '🌐 Join Online Game',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 19)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            if (_statusMsg.isNotEmpty)
              _StatusBanner(message: _statusMsg, isError: _statusMsg.startsWith('❌'))
                  .animate().fadeIn(),
            const SizedBox(height: 20),

            if (widget.isHost) ...[
              if (_room != null) _buildHostView(),
            ] else ...[
              _buildJoinView(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHostView() {
    final room = _room!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room code display
        Center(
          child: Column(
            children: [
              Text('Room Code',
                  style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: room.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Code copied!',
                          style: GoogleFonts.nunito(color: Colors.white)),
                      backgroundColor: AppColors.darkCard,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: AppColors.primary.withOpacity(0.15),
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        room.code,
                        style: GoogleFonts.fredoka(
                          fontSize: 36,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.copy_rounded,
                          color: AppColors.textMuted, size: 20),
                    ],
                  ),
                ),
              ).animate().scale(curve: Curves.elasticOut),
              const SizedBox(height: 8),
              Text('Tap to copy',
                  style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Players
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Players (${room.players.length}/${room.maxPlayers})',
                style: GoogleFonts.fredoka(
                    fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
            Text('Waiting for ${room.maxPlayers - room.players.length} more...',
                style: GoogleFonts.nunito(
                    fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 12),
        ...room.players.asMap().entries.map((e) => _PlayerTile(
              player: e.value,
              index: e.key,
            ).animate(delay: (e.key * 60).ms).slideX(begin: -0.1)),

        // Empty slots
        ...List.generate(room.maxPlayers - room.players.length, (i) =>
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.darkCard,
              border: Border.all(
                  color: AppColors.darkBorder,
                  style: BorderStyle.solid),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_add_rounded,
                    color: AppColors.textMuted, size: 20),
                const SizedBox(width: 10),
                Text('Waiting for player...',
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          )),

        const SizedBox(height: 28),

        // Settings summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.darkCard,
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              _SettingChip('🎮', room.gameMode),
              const SizedBox(width: 12),
              _SettingChip('⏱️', '${room.turnTimer}s'),
              const SizedBox(width: 12),
              _SettingChip('👥', '${room.maxPlayers} max'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Invite Friends button
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/friends', extra: {
              'roomCode': room.code,
              'gameMode': room.gameMode,
            }),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryLight,
              side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Text('📨', style: TextStyle(fontSize: 18)),
            label: Text('Invite Friends',
                style: GoogleFonts.fredoka(fontSize: 16, color: AppColors.primaryLight)),
          ),
        ).animate(delay: 200.ms).fadeIn(),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: room.players.length >= 2 ? _startGame : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: room.players.length >= 2
                  ? AppColors.primary
                  : AppColors.darkCard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 6,
            ),
            child: Text(
              room.players.length >= 2
                  ? '🎲 Start Game'
                  : 'Need at least 2 players',
              style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white),
            ),
          ),
        ).animate(delay: 300.ms).fadeIn(),
      ],
    );
  }

  Widget _buildJoinView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter Room Code',
            style: GoogleFonts.fredoka(
                fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codeController,
                style: GoogleFonts.fredoka(
                    fontSize: 22, color: Colors.white, letterSpacing: 6),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'ABC123',
                  hintStyle: GoogleFonts.fredoka(
                      fontSize: 22,
                      color: Colors.white24,
                      letterSpacing: 6),
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.darkCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.darkBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.darkBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _joinRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 17),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Join',
                      style: GoogleFonts.fredoka(
                          fontSize: 16, color: Colors.white)),
            ),
          ],
        ),

        if (_room != null) ...[
          const SizedBox(height: 24),
          Text('Room Found!',
              style: GoogleFonts.fredoka(
                  fontSize: 17, color: AppColors.greenPlayer)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.greenPlayer.withOpacity(0.1),
              border: Border.all(
                  color: AppColors.greenPlayer.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Text('✅', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hosted by ${_room!.hostName}',
                          style: GoogleFonts.fredoka(
                              fontSize: 15, color: Colors.white)),
                      Text(
                          '${_room!.players.length}/${_room!.maxPlayers} players · ${_room!.gameMode}',
                          style: GoogleFonts.nunito(
                              fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().scale(curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.darkCard,
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accent),
                ),
                const SizedBox(width: 10),
                Text('Waiting for host to start the game...',
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final RoomPlayer player;
  final int index;
  const _PlayerTile({required this.player, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.darkCard,
        border: Border.all(
            color: player.isHost
                ? AppColors.accent.withOpacity(0.4)
                : AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Text(player.isHost ? '👑' : '🎮',
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(player.name,
                style: GoogleFonts.fredoka(fontSize: 15, color: Colors.white)),
          ),
          if (player.isHost)
            _Badge('HOST', AppColors.accent)
          else if (player.isReady)
            _Badge('READY', AppColors.greenPlayer)
          else
            _Badge('...', AppColors.textMuted),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            style: GoogleFonts.nunito(
                fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      );
}

class _SettingChip extends StatelessWidget {
  final String emoji;
  final String label;
  const _SettingChip(this.emoji, this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.white70)),
        ],
      );
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool isError;
  const _StatusBanner({required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isError
              ? AppColors.error.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.1),
          border: Border.all(
              color: isError
                  ? AppColors.error.withOpacity(0.3)
                  : AppColors.primary.withOpacity(0.3)),
        ),
        child: Text(message,
            style: GoogleFonts.nunito(
                fontSize: 13,
                color: isError ? AppColors.error : Colors.white70)),
      );
}
