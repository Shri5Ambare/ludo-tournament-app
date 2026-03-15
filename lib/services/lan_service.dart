// lib/services/lan_service.dart
// LAN/Hotspot multiplayer service using WebSocket over local WiFi

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lanServiceProvider = Provider<LanService>((ref) => LanService());

enum LanRole { none, host, client }

class LanGameMessage {
  final String type; // 'roll', 'move', 'state', 'join', 'ping'
  final Map<String, dynamic> data;
  final String playerId;

  LanGameMessage({
    required this.type,
    required this.data,
    required this.playerId,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'data': data,
        'playerId': playerId,
      };

  factory LanGameMessage.fromJson(Map<String, dynamic> json) =>
      LanGameMessage(
        type: json['type'] as String,
        data: json['data'] as Map<String, dynamic>,
        playerId: json['playerId'] as String,
      );
}

class LanService {
  LanRole _role = LanRole.none;
  HttpServer? _server;
  WebSocket? _clientSocket;
  final List<WebSocket> _connectedClients = [];

  // Stream of incoming messages
  final _messageController =
      StreamController<LanGameMessage>.broadcast();
  Stream<LanGameMessage> get messages => _messageController.stream;

  // Connection status stream
  final _connectionController =
      StreamController<String>.broadcast();
  Stream<String> get connectionStatus => _connectionController.stream;

  LanRole get role => _role;
  bool get isHost => _role == LanRole.host;
  bool get isClient => _role == LanRole.client;
  int get connectedClientCount => _connectedClients.length;

  // ─────────────────────────────────────────────
  // HOST
  // ─────────────────────────────────────────────

  /// Start hosting a game server on local WiFi
  Future<String?> startHost({int port = 8765}) async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _role = LanRole.host;

      // Get local IP
      final ip = await _getLocalIP();
      _connectionController.add('HOST_STARTED:$ip:$port');

      // Listen for WebSocket connections
      _server!.transform(WebSocketTransformer()).listen((ws) {
        _connectedClients.add(ws);
        _connectionController.add('CLIENT_JOINED:${_connectedClients.length}');

        ws.listen(
          (data) => _handleIncoming(data, ws),
          onDone: () {
            _connectedClients.remove(ws);
            _connectionController
                .add('CLIENT_LEFT:${_connectedClients.length}');
          },
        );
      });

      return '$ip:$port';
    } catch (e) {
      _connectionController.add('HOST_ERROR:$e');
      return null;
    }
  }

  /// Broadcast a message to all connected clients (host only)
  void broadcast(LanGameMessage message) {
    if (!isHost) return;
    final json = jsonEncode(message.toJson());
    for (final client in List.from(_connectedClients)) {
      try {
        client.add(json);
      } catch (_) {}
    }
  }

  // ─────────────────────────────────────────────
  // CLIENT
  // ─────────────────────────────────────────────

  /// Connect to a host as client
  Future<bool> connectToHost(String ipPort) async {
    try {
      final uri = Uri.parse('ws://$ipPort');
      _clientSocket = await WebSocket.connect(uri.toString());
      _role = LanRole.client;
      _connectionController.add('CONNECTED_TO_HOST');

      _clientSocket!.listen(
        (data) => _handleIncoming(data, null),
        onDone: () => _connectionController.add('DISCONNECTED'),
        onError: (_) => _connectionController.add('CONNECTION_ERROR'),
      );
      return true;
    } catch (e) {
      _connectionController.add('CONNECT_ERROR:$e');
      return false;
    }
  }

  /// Send a message to host (client only)
  void sendToHost(LanGameMessage message) {
    if (!isClient || _clientSocket == null) return;
    try {
      _clientSocket!.add(jsonEncode(message.toJson()));
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // SHARED
  // ─────────────────────────────────────────────

  void _handleIncoming(dynamic data, WebSocket? source) {
    try {
      final map = jsonDecode(data as String) as Map<String, dynamic>;
      final msg = LanGameMessage.fromJson(map);
      _messageController.add(msg);

      // If host, relay to all other clients
      if (isHost && source != null) {
        for (final client in List.from(_connectedClients)) {
          if (client != source) {
            try { client.add(data); } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  Future<String> _getLocalIP() async {
    final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false);
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
          return addr.address;
        }
      }
    }
    return '127.0.0.1';
  }

  Future<void> disconnect() async {
    _role = LanRole.none;
    await _clientSocket?.close();
    _clientSocket = null;
    for (final c in _connectedClients) {
      await c.close();
    }
    _connectedClients.clear();
    await _server?.close(force: true);
    _server = null;
    _connectionController.add('DISCONNECTED');
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
