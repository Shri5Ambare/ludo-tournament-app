// lib/screens/game/hotspot_lobby_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import 'package:ludo_tournament_app/core/constants/app_constants.dart';
import '../../core/constants/board_paths.dart';
import '../../models/game_models.dart';
import '../../providers/chat_provider.dart';
import '../../services/lan_service.dart';

class HotspotLobbyScreen extends ConsumerStatefulWidget {
  final bool isHost;
  const HotspotLobbyScreen({super.key, required this.isHost});

  @override
  ConsumerState<HotspotLobbyScreen> createState() => _HotspotLobbyScreenState();
}

class _HotspotLobbyScreenState extends ConsumerState<HotspotLobbyScreen> {
  final LanService _lanService = LanService();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final List<String> _connectedPlayers = [];
  CustomRules _customRules = const CustomRules();
  String? _hostAddress;
  String _statusMessage = '';
  bool _isConnecting = false;
  StreamSubscription? _statusSub;
  StreamSubscription? _messageSub;

  @override
  void initState() {
    super.initState();
    _statusSub = _lanService.connectionStatus.listen(_onConnectionStatus);
    _messageSub = _lanService.messages.listen(_onMessage);
    // Wire incoming chat messages to ChatNotifier
    _lanService.onChatMessage = (json) =>
        ref.read(chatProvider.notifier).receiveFromJson(json);
    if (widget.isHost) {
      _nameController.text = 'Host';
      _connectedPlayers.add('You (Host)');
      _startHost();
    } else {
      _nameController.text = 'Player ${1 + (DateTime.now().millisecond % 100)}';
    }
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _messageSub?.cancel();
    _lanService.dispose();
    _ipController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startHost() async {
    setState(() => _statusMessage = 'Starting hotspot server...');
    final addr = await _lanService.startHost();
    if (addr != null) {
      setState(() {
        _hostAddress = addr;
        _statusMessage = 'Waiting for players to join...';
      });
    } else {
      setState(() => _statusMessage = '❌ Failed to start server');
    }
  }

  Future<void> _connectToHost() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Connecting to $ip...';
    });
    final success = await _lanService.connectToHost(ip);
    setState(() => _isConnecting = false);
    if (!success) {
      setState(() => _statusMessage = '❌ Could not connect. Check IP and try again.');
    }
  }

  void _onConnectionStatus(String status) {
    if (!mounted) return;
    if (status.startsWith('CLIENT_JOINED')) {
      final count = status.split(':').last;
      setState(() {
        _connectedPlayers.add('Player ${_connectedPlayers.length + 1}');
        _statusMessage = '$count player(s) connected';
      });
    } else if (status.startsWith('CONNECTED_TO_HOST')) {
      setState(() => _statusMessage = '✅ Connected! Waiting for host to start...');
      // Send our name to the host
      _lanService.broadcast(LanGameMessage(
        type: 'player_joined',
        data: {'name': _nameController.text.trim().isEmpty ? 'Guest' : _nameController.text.trim()},
        playerId: 'client_${DateTime.now().millisecondsSinceEpoch}',
      ));
    } else if (status == 'DISCONNECTED') {
      setState(() => _statusMessage = '🔌 Disconnected');
    } else if (status == 'CONNECTION_ERROR') {
      setState(() => _statusMessage = '❌ Connection error');
    }
  }

  void _onMessage(LanGameMessage msg) {
    if (!mounted) return;
    if (msg.type == 'start_game') {
      final configs = (msg.data['playerConfigs'] as List)
          .cast<Map<String, dynamic>>();
      // Client is always the last joined player
      final clientIndex = configs.length - 1;
      final clientName = configs[clientIndex]['name'] as String? ?? 'Player';

      // Wire outgoing chat to LAN
      ref.read(chatProvider.notifier).onSend = (chatMsg) {
        _lanService.sendChat(
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
        'gameMode': msg.data['gameMode'],
        'turnTimerSeconds': msg.data['turnTimerSeconds'],
        'customRules': CustomRules.fromJson(msg.data['customRules'] ?? {}),
        'localPlayerName': clientName,
        'localPlayerIndex': clientIndex,
      });
    } else if (msg.type == 'player_joined') {
      final playerName = msg.data['name'] as String;
      setState(() {
        if (!_connectedPlayers.contains(playerName)) {
           _connectedPlayers.add(playerName);
        }
      });
    } else if (msg.type == 'lobby_update') {
      setState(() {
        if (msg.data.containsKey('customRules')) {
          _customRules = CustomRules.fromJson(msg.data['customRules']);
        }
      });
    }
  }

  void _broadcastLobbyUpdate() {
    if (!widget.isHost) return;
    _lanService.broadcast(LanGameMessage(
      type: 'lobby_update',
      data: {
        'customRules': _customRules.toJson(),
      },
      playerId: 'host',
    ));
  }

  void _startGame() {
    final configs = _connectedPlayers.asMap().entries.map((e) => {
      'name': e.value,
      'type': e.key == 0 ? PlayerType.human : PlayerType.human,
      'avatar': '🧑',
    }).toList();

    final msg = LanGameMessage(
      type: 'start_game',
      data: {
        'playerConfigs': configs,
        'gameMode': GameMode.classic,
        'turnTimerSeconds': 30,
        'customRules': _customRules.toJson(),
      },
      playerId: 'host',
    );
    _lanService.broadcast(msg);

    // Host is always player index 0 — wire outgoing chat to LAN
    ref.read(chatProvider.notifier).onSend = (chatMsg) {
      _lanService.sendChat(
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
      'gameMode': GameMode.classic,
      'turnTimerSeconds': 30,
      'customRules': _customRules,
      'localPlayerName': configs[0]['name'] as String? ?? 'Host',
      'localPlayerIndex': 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.isHost ? 'HOST HOTSPOT' : 'JOIN HOTSPOT',
          style: GoogleFonts.fredoka(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).iconTheme.color),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const BouncingScrollPhysics(),
        child: widget.isHost ? _buildHostView() : _buildClientView(),
      ),
    );
  }

  Widget _buildHostView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status card
        _StatusCard(message: _statusMessage, isError: _statusMessage.startsWith('❌')),
        const SizedBox(height: 24),

        const _SectionTitle(title: 'YOUR DISPLAY NAME'),
        const SizedBox(height: 12),
        _buildNameInput(),
        const SizedBox(height: 32),

        // QR Code + IP Section
        if (_hostAddress != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.05), width: 2),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: -5),
                    ],
                  ),
                  child: QrImageView(
                    data: 'ludo://$_hostAddress',
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.textDark),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.textDark),
                  ),
                ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                const SizedBox(height: 24),
                Text('YOUR FRIENDS SCAN THIS QR',
                    style: GoogleFonts.fredoka(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.4), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _hostAddress!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('IP Address copied!',
                            style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold)),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_hostAddress!,
                            style: GoogleFonts.fredoka(
                                fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Icon(Icons.copy_rounded, color: AppColors.primary.withValues(alpha: 0.4), size: 18),
                      ],
                    ),
                  ),
                ).animate(delay: 300.ms).fadeIn(),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],

        const _SectionTitle(title: 'ADVANCED RULES'),
        const SizedBox(height: 12),
        _buildHouseRules(),
        const SizedBox(height: 32),

        // Connected players
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             const _SectionTitle(title: 'PLAYERS'),
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('${_connectedPlayers.length}/4',
                  style: GoogleFonts.fredoka(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._connectedPlayers.asMap().entries.map((e) => _PlayerRow(
              index: e.key,
              name: e.value,
              isHost: e.key == 0,
            ).animate(delay: (e.key * 60).ms).slideX(begin: -0.1).fadeIn()),
        const SizedBox(height: 40),

        // Start button
        SizedBox(
          width: double.infinity,
          height: 64,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: _connectedPlayers.length >= 2 
                  ? const LinearGradient(colors: [AppColors.primary, Color(0xFF7B85FF)])
                  : null,
              color: _connectedPlayers.length < 2 ? Colors.grey.shade200 : null,
              boxShadow: _connectedPlayers.length >= 2 
                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: _connectedPlayers.length >= 2 ? _startGame : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(
                _connectedPlayers.length >= 2
                    ? 'START GAME'
                    : 'WAITING FOR PLAYERS...',
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildNameInput() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _nameController,
        style: GoogleFonts.fredoka(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Enter your name...',
          hintStyle: GoogleFonts.fredoka(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.2), fontSize: 16, fontWeight: FontWeight.w500),
          prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary.withValues(alpha: 0.4), size: 22),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
          ),
        ),
        onChanged: (v) {
          if (widget.isHost) {
            setState(() => _connectedPlayers[0] = v.isEmpty ? 'You (Host)' : '$v (Host)');
          }
        },
      ),
    );
  }

  Widget _buildHouseRules() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          iconColor: AppColors.primary,
          collapsedIconColor: Theme.of(context).iconTheme.color?.withValues(alpha: 0.3),
          title: Text('Advanced Rules',
              style: GoogleFonts.fredoka(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
          subtitle: Text('Modify game mechanics',
              style: GoogleFonts.nunito(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.3), fontWeight: FontWeight.bold)),
          children: [
             const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Divider(color: AppColors.lightBg, height: 1),
            ),
            _ruleToggle('6 gives another turn', _customRules.sixGivesExtraTurn, (v) { setState(() => _customRules = _customRules.copyWith(sixGivesExtraTurn: v)); _broadcastLobbyUpdate(); }),
            _ruleToggle('6 brings a coin out', _customRules.sixBringsCoinOut, (v) { setState(() => _customRules = _customRules.copyWith(sixBringsCoinOut: v)); _broadcastLobbyUpdate(); }),
            _ruleToggle('Show safe cells (stars)', _customRules.safeZonesEnabled, (v) { setState(() => _customRules = _customRules.copyWith(safeZonesEnabled: v)); _broadcastLobbyUpdate(); }),
            _ruleToggle('3 consecutive 1s cuts one own coin', _customRules.tripleOneKillsOwn, (v) { setState(() => _customRules = _customRules.copyWith(tripleOneKillsOwn: v)); _broadcastLobbyUpdate(); }),
            _ruleToggle('Skip a turn on 3 consecutive 1s', _customRules.tripleOneSkipsTurn, (v) { setState(() => _customRules = _customRules.copyWith(tripleOneSkipsTurn: v)); _broadcastLobbyUpdate(); }),
            _ruleToggle('3 consecutive 6s brings a coin out', _customRules.tripleSixBringsCoinOut, (v) { setState(() => _customRules = _customRules.copyWith(tripleSixBringsCoinOut: v)); _broadcastLobbyUpdate(); }),
            _ruleToggle('3 consecutive 6s forfeits turn', _customRules.tripleSixForfeit, (v) { setState(() => _customRules = _customRules.copyWith(tripleSixForfeit: v)); _broadcastLobbyUpdate(); }),
            _ruleToggle('Gains another turn on cutting a coin', _customRules.cutGrantsExtraTurn, (v) { setState(() => _customRules = _customRules.copyWith(cutGrantsExtraTurn: v)); _broadcastLobbyUpdate(); }),
            _ruleToggle('Gains another turn on reaching home', _customRules.homeGrantsExtraTurn, (v) { setState(() => _customRules = _customRules.copyWith(homeGrantsExtraTurn: v)); _broadcastLobbyUpdate(); }),
            _ruleToggle('Must cut a coin to enter home lane', _customRules.mustCutToEnterHomeLane, (v) { setState(() => _customRules = _customRules.copyWith(mustCutToEnterHomeLane: v)); _broadcastLobbyUpdate(); }),
            _ruleToggle('Must cut opponent if possible', _customRules.mustCutIfCuttable, (v) { setState(() => _customRules = _customRules.copyWith(mustCutIfCuttable: v)); _broadcastLobbyUpdate(); }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _ruleToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      title: Text(title, style: GoogleFonts.fredoka(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary.withValues(alpha: 0.2),
      thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return Colors.white;
      }),
    );
  }

  Widget _buildClientView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusCard(
            message: _statusMessage.isEmpty
                ? 'Enter the host\'s IP address to join'
                : _statusMessage,
            isError: _statusMessage.startsWith('❌')),
        const SizedBox(height: 32),
        const _SectionTitle(title: 'YOUR DISPLAY NAME'),
        const SizedBox(height: 12),
        _buildNameInput(),
        const SizedBox(height: 40),
        const _SectionTitle(title: 'HOST IP ADDRESS'),
        const SizedBox(height: 16),
        Container(
           padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _ipController,
                style: GoogleFonts.fredoka(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                keyboardType: TextInputType.text,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '192.168.1.X:8765',
                  hintStyle: GoogleFonts.nunito(color: AppColors.textDark.withValues(alpha: 0.1), fontSize: 18, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: AppColors.lightBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 64,
                 child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7B85FF)]),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isConnecting ? null : _connectToHost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: _isConnecting
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        : Text('JOIN SESSION',
                            style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Make sure you\'re on the same WiFi hotspot as the host. The host will share their IP address or QR code.',
                  style: GoogleFonts.nunito(
                      fontSize: 13, color: AppColors.info, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String message;
  final bool isError;
  const _StatusCard({required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError
              ? AppColors.error.withValues(alpha: 0.1)
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: (isError ? AppColors.error : AppColors.primary)
                  .withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          isError
              ? const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24)
              : const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.fredoka(
                      fontSize: 14,
                      color: isError ? AppColors.error : AppColors.primary,
                      fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title,
          style: GoogleFonts.fredoka(
              fontSize: 14, color: AppColors.textDark.withValues(alpha: 0.4), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final int index;
  final String name;
  final bool isHost;
  const _PlayerRow(
      {required this.index, required this.name, this.isHost = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: isHost ? Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 2) : null,
      ),
      child: Row(
        children: [
           Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: BoardPaths.playerColors[index % 4].withValues(alpha: 0.1)
            ),
            child: Center(
                child: Text(isHost ? '👑' : '🎮',
                    style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(name,
                style: GoogleFonts.fredoka(
                    fontSize: 16, color: AppColors.textDark, fontWeight: FontWeight.bold)),
          ),
          if (isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('HOST',
                  style: GoogleFonts.fredoka(
                      fontSize: 10,
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.greenPlayer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('READY',
                  style: GoogleFonts.fredoka(
                      fontSize: 10,
                      color: AppColors.greenPlayer,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
        ],
      ),
    );
  }
}
