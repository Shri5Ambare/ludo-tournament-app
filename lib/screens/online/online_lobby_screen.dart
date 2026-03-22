// lib/screens/online/online_lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ludo_tournament_app/core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/game_models.dart';
import '../../providers/chat_provider.dart';
import '../../services/supabase_service.dart';

class OnlineLobbyScreen extends ConsumerStatefulWidget {
  final bool isHost;
  final String? roomId;

  const OnlineLobbyScreen({super.key, required this.isHost, this.roomId});

  @override
  ConsumerState<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends ConsumerState<OnlineLobbyScreen> {
  OnlineRoom? _room;
  List<RoomPlayer> _players = [];
  CustomRules _customRules = const CustomRules();
  String _statusMessage = 'INITIALIZING...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLobby();
  }

  Future<void> _initLobby() async {
    final supabase = ref.read(supabaseServiceProvider);

    if (widget.isHost) {
      try {
        final room = await supabase.createRoom(
          gameMode: GameMode.classic,
          turnTimer: 30,
          maxPlayers: 4,
        );
        if (mounted && room != null) {
          setState(() {
            _room = room;
            _statusMessage = 'WAITING FOR PLAYERS...';
            _isLoading = false;
          });
          _subscribeToRoom(room.id);
        }
      } catch (e) {
        if (mounted) setState(() => _statusMessage = 'ERROR: $e');
      }
    } else if (widget.roomId != null) {
      try {
        final room = await supabase.joinRoom(widget.roomId!);
        if (mounted && room != null) {
          setState(() {
            _room = room;
            _statusMessage = 'JOINED LOBBY';
            _isLoading = false;
          });
          _subscribeToRoom(room.id);
        }
      } catch (e) {
        if (mounted) setState(() => _statusMessage = 'FAILED TO JOIN: $e');
      }
    }
  }

  void _subscribeToRoom(String roomId) {
    final supabase = ref.read(supabaseServiceProvider);
    
    supabase.onRoomPlayersChanged = () async {
      final players = await supabase.getRoomPlayers(roomId);
      if (mounted) setState(() => _players = players);
    };
    
    supabase.onRulesChanged = (rules) {
      if (mounted) setState(() => _customRules = rules);
    };

    supabase.onRoomStatusChanged = (status) {
      if (status == RoomStatus.inProgress && !widget.isHost) {
        _startGame(); // Navigate guests
      }
    };

    supabase.subscribeToRoom(roomId);

    // Initial player fetch
    supabase.getRoomPlayers(roomId).then((p) {
      if (mounted) setState(() => _players = p);
    });

    // Wire chat
    ref.read(chatProvider.notifier).onSend = (chatMsg) {
       supabase.broadcastChat(
         playerName: chatMsg.playerName,
         playerIndex: chatMsg.playerIndex,
         content: chatMsg.content,
         type: chatMsg.type.name,
         messageId: chatMsg.id,
         timestamp: chatMsg.timestamp.toIso8601String(),
       );
    };
  }

  void _updateRules(CustomRules newRules) {
    if (!widget.isHost || _room == null) return;
    setState(() => _customRules = newRules);
    ref.read(supabaseServiceProvider).updateRoomRules(_room!.id, newRules);
  }

  void _startGame() async {
    final supabase = ref.read(supabaseServiceProvider);
    if (widget.isHost && _room != null) {
      await supabase.updateRoomSettings(_room!.id, status: RoomStatus.inProgress);
    }
    
    if (_room == null) return;
    
    final playerConfigs = _players.map((p) => {
      'name': p.name,
      'type': p.id == supabase.currentUserId ? PlayerType.human : PlayerType.remote,
      'avatar': p.avatarEmoji,
    }).toList();
    
    if (!mounted) return;
    context.pushReplacement('/game', extra: {
      'playerConfigs': playerConfigs,
      'gameMode': _room?.gameMode ?? GameMode.classic,
      'turnTimerSeconds': _room?.turnTimer ?? 30,
      'customRules': _customRules,
      'localPlayerName': supabase.username ?? 'Player',
      'localPlayerIndex': _players.indexWhere((p) => p.id == supabase.currentUserId),
      'isOnline': true,
      'roomId': _room?.id,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.isHost ? 'HOST LOBBY' : 'ONLINE LOBBY',
            style: GoogleFonts.fredoka(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _OnlineStatusBanner(message: _statusMessage),
                  const SizedBox(height: 24),
                  if (_room != null) _buildRoomCodeCard(_room!),
                  const SizedBox(height: 32),
                  const _SectionTitle(title: 'PLAYERS IN LOBBY'),
                  const SizedBox(height: 16),
                  ..._players.map((p) => _OnlinePlayerTile(player: p)),
                  const SizedBox(height: 32),
                  const _SectionTitle(title: 'GAME SETTINGS'),
                  const SizedBox(height: 16),
                  _buildSettingsCard(),
                  const SizedBox(height: 48),
                  if (widget.isHost)
                    _buildStartButton()
                  else
                    _buildWaitingButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildRoomCodeCard(OnlineRoom room) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text('ROOM CODE', style: GoogleFonts.fredoka(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(room.code, style: GoogleFonts.fredoka(fontSize: 42, color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 4)),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: room.code));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ROOM CODE COPIED!')));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          _buildModeSelector(),
          const Divider(height: 32),
          _buildPlayerCountSelector(),
          const Divider(height: 32),
          _buildTimerSelector(),
          const Divider(height: 32),
          _ruleToggle('6 gives another turn', _customRules.sixGivesExtraTurn, (v) => _updateRules(_customRules.copyWith(sixGivesExtraTurn: v))),
          _ruleToggle('6 brings a coin out', _customRules.sixBringsCoinOut, (v) => _updateRules(_customRules.copyWith(sixBringsCoinOut: v))),
          _ruleToggle('Show safe cells (stars)', _customRules.safeZonesEnabled, (v) => _updateRules(_customRules.copyWith(safeZonesEnabled: v))),
          _ruleToggle('3 consecutive 1s cuts own coin', _customRules.tripleOneKillsOwn, (v) => _updateRules(_customRules.copyWith(tripleOneKillsOwn: v))),
          _ruleToggle('Skip a turn on 3 consecutive 1s', _customRules.tripleOneSkipsTurn, (v) => _updateRules(_customRules.copyWith(tripleOneSkipsTurn: v))),
          _ruleToggle('3 consecutive 6s brings a coin out', _customRules.tripleSixBringsCoinOut, (v) => _updateRules(_customRules.copyWith(tripleSixBringsCoinOut: v))),
          _ruleToggle('3 consecutive 6s forfeits turn', _customRules.tripleSixForfeit, (v) => _updateRules(_customRules.copyWith(tripleSixForfeit: v))),
          _ruleToggle('Gains another turn on cutting a coin', _customRules.cutGrantsExtraTurn, (v) => _updateRules(_customRules.copyWith(cutGrantsExtraTurn: v))),
          _ruleToggle('Gains another turn on reaching home', _customRules.homeGrantsExtraTurn, (v) => _updateRules(_customRules.copyWith(homeGrantsExtraTurn: v))),
          _ruleToggle('Must cut a coin to enter home lane', _customRules.mustCutToEnterHomeLane, (v) => _updateRules(_customRules.copyWith(mustCutToEnterHomeLane: v))),
          _ruleToggle('Must cut opponent if possible', _customRules.mustCutIfCuttable, (v) => _updateRules(_customRules.copyWith(mustCutIfCuttable: v))),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return _SettingRow(
      icon: '🏠',
      label: 'GAME MODE',
      value: _room?.gameMode.toUpperCase() ?? 'CLASSIC',
      onTap: widget.isHost ? () async {
        final newMode = _room?.gameMode == GameMode.classic ? GameMode.quick : GameMode.classic;
        await ref.read(supabaseServiceProvider).updateRoomSettings(_room!.id, gameMode: newMode);
        setState(() => _room = _room?.copyWith(gameMode: newMode));
      } : null,
    );
  }

  Widget _buildPlayerCountSelector() {
    return _SettingRow(
      icon: '👥',
      label: 'MAX PLAYERS',
      value: '${_room?.maxPlayers ?? 4} PLAYERS',
      onTap: widget.isHost ? () async {
        final current = _room?.maxPlayers ?? 4;
        final next = current == 4 ? 2 : (current + 1);
        await ref.read(supabaseServiceProvider).updateRoomSettings(_room!.id, maxPlayers: next);
        setState(() => _room = _room?.copyWith(maxPlayers: next));
      } : null,
    );
  }

  Widget _buildTimerSelector() {
    return _SettingRow(
      icon: '⏱️',
      label: 'TURN TIMER',
      value: '${_room?.turnTimer ?? 30}s',
      onTap: widget.isHost ? () async {
        final current = _room?.turnTimer ?? 30;
        final next = current == 60 ? 15 : (current + 15);
        await ref.read(supabaseServiceProvider).updateRoomSettings(_room!.id, turnTimer: next);
        setState(() => _room = _room?.copyWith(turnTimer: next));
      } : null,
    );
  }

  Widget _ruleToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          Switch.adaptive(
            value: value,
            onChanged: widget.isHost ? onChanged : null,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    final canStart = _players.isNotEmpty;
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: canStart ? const LinearGradient(colors: [AppColors.primary, Color(0xFF7B85FF)]) : null,
        color: canStart ? null : Colors.grey[300],
        boxShadow: canStart ? [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ] : [],
      ),
      child: ElevatedButton(
        onPressed: canStart ? _startGame : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text('START GAME', style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
      ),
    );
  }

  Widget _buildWaitingButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Text('WAITING FOR HOST...', style: GoogleFonts.fredoka(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}

class _OnlineStatusBanner extends StatelessWidget {
  final String message;
  const _OnlineStatusBanner({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Text(message, style: GoogleFonts.fredoka(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _OnlinePlayerTile extends StatelessWidget {
  final RoomPlayer player;
  const _OnlinePlayerTile({required this.player});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Center(child: Text(player.avatarEmoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name.toUpperCase(), style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                Text('PLAYER', style: GoogleFonts.fredoka(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          if (player.isReady)
            const Icon(Icons.check_circle, color: AppColors.success)
          else if (player.isHost)
            const Icon(Icons.star, color: AppColors.accent),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.fredoka(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Text(value, style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ],
            ),
            const Spacer(),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: AppColors.primary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }
}
