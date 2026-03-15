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
import '../../models/game_models.dart';
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
  final List<String> _connectedPlayers = ['You (Host)'];
  String? _hostAddress;
  String _statusMessage = '';
  bool _isConnecting = false;
  bool _isReady = false;
  StreamSubscription? _statusSub;
  StreamSubscription? _messageSub;

  @override
  void initState() {
    super.initState();
    _statusSub = _lanService.connectionStatus.listen(_onConnectionStatus);
    _messageSub = _lanService.messages.listen(_onMessage);
    if (widget.isHost) _startHost();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _messageSub?.cancel();
    _lanService.dispose();
    _ipController.dispose();
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
      context.pushReplacement('/game', extra: {
        'playerConfigs': configs,
        'gameMode': msg.data['gameMode'],
        'turnTimerSeconds': msg.data['turnTimerSeconds'],
      });
    }
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
      },
      playerId: 'host',
    );
    _lanService.broadcast(msg);

    context.pushReplacement('/game', extra: {
      'playerConfigs': configs,
      'gameMode': GameMode.classic,
      'turnTimerSeconds': 30,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.isHost ? '📡 Host Game' : '📡 Join Game',
          style: GoogleFonts.fredoka(color: Colors.white, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
        const SizedBox(height: 20),

        // QR Code + IP
        if (_hostAddress != null) ...[
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      )
                    ],
                  ),
                  child: QrImageView(
                    data: 'ludo://$_hostAddress',
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.darkBg,
                  ),
                ).animate().scale(curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text('Scan QR or enter IP manually',
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _hostAddress!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('IP copied!',
                            style: GoogleFonts.nunito(color: Colors.white)),
                        backgroundColor: AppColors.darkCard,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_hostAddress!,
                            style: GoogleFonts.fredoka(
                                fontSize: 18, color: AppColors.primaryLight)),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy, color: AppColors.textMuted, size: 16),
                      ],
                    ),
                  ),
                ).animate(delay: 300.ms).fadeIn(),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],

        // Connected players
        _SectionTitle(title: 'Connected Players (${_connectedPlayers.length}/4)'),
        const SizedBox(height: 10),
        ..._connectedPlayers.asMap().entries.map((e) => _PlayerRow(
              index: e.key,
              name: e.value,
              isHost: e.key == 0,
            ).animate(delay: (e.key * 60).ms).slideX(begin: -0.1)),
        const SizedBox(height: 28),

        // Start button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _connectedPlayers.length >= 2 ? _startGame : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _connectedPlayers.length >= 2
                  ? AppColors.primary
                  : AppColors.darkCard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 8,
            ),
            child: Text(
              _connectedPlayers.length >= 2
                  ? '🎲 Start Game (${_connectedPlayers.length} players)'
                  : 'Waiting for players...',
              style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white),
            ),
          ),
        ).animate(delay: 400.ms).fadeIn(),
      ],
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
        const SizedBox(height: 24),
        _SectionTitle(title: 'Host IP Address'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ipController,
                style: GoogleFonts.nunito(color: Colors.white),
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: '192.168.1.X:8765',
                  hintStyle: GoogleFonts.nunito(
                      color: Colors.white38, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.darkCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.darkBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.darkBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isConnecting ? null : _connectToHost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Join',
                      style:
                          GoogleFonts.fredoka(fontSize: 15, color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Make sure you\'re on the same WiFi hotspot as the host. '
                  'The host will share their IP address or QR code.',
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: Colors.white70),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isError
            ? AppColors.error.withOpacity(0.1)
            : AppColors.primary.withOpacity(0.1),
        border: Border.all(
            color: isError
                ? AppColors.error.withOpacity(0.4)
                : AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          isError
              ? const Icon(Icons.error_outline,
                  color: AppColors.error, size: 20)
              : const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: isError ? AppColors.error : Colors.white70),
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
    return Text(title,
        style: GoogleFonts.fredoka(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white));
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.darkCard,
        border: Border.all(
            color: isHost
                ? AppColors.accent.withOpacity(0.4)
                : AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Text(isHost ? '👑' : '🎮',
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style: GoogleFonts.nunito(
                    fontSize: 14, color: Colors.white)),
          ),
          if (isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('HOST',
                  style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.greenPlayer.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('READY',
                  style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: AppColors.greenPlayer,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
