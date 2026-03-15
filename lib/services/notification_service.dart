// lib/services/notification_service.dart
//
// Local and push notification service.
// Uses flutter_local_notifications for local alerts (e.g. "Your turn!").
// For FCM push notifications in a real deployment, add firebase_messaging.

import 'dart:async';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  // In-app notification queue (shown as banners inside the app)
  final _controller = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get notifications => _controller.stream;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    // Real impl: initialize flutter_local_notifications and FCM here
    debugPrint('NotificationService initialized');
  }

  // ── Tournament notifications ───────────────────────────────────────────

  void notifyYourTurn(String playerName) {
    _push(AppNotification(
      title: "Your Turn! 🎲",
      body: "$playerName, roll the dice!",
      type: NotificationType.turn,
      icon: '🎲',
    ));
  }

  void notifyGroupGameReady(String groupLabel) {
    _push(AppNotification(
      title: "Match Ready! ⚔️",
      body: "$groupLabel game is about to start.",
      type: NotificationType.tournamentMatch,
      icon: '🏆',
    ));
  }

  void notifyFinalsReady() {
    _push(AppNotification(
      title: "Finals Time! 🏆",
      body: "You've made it to the finals. Compete for the championship!",
      type: NotificationType.tournamentFinals,
      icon: '🥇',
    ));
  }

  void notifyTokenCut(String cutterName) {
    _push(AppNotification(
      title: "Token Cut! ✂️",
      body: "$cutterName cut your token! Strike back.",
      type: NotificationType.gameEvent,
      icon: '✂️',
    ));
  }

  void notifyPlayerWon(String playerName) {
    _push(AppNotification(
      title: "Game Over! 🎉",
      body: "$playerName won the game!",
      type: NotificationType.gameOver,
      icon: '🎉',
    ));
  }

  void notifyDailyReward() {
    _push(AppNotification(
      title: "Daily Reward! 🎁",
      body: "Your daily bonus is ready to claim!",
      type: NotificationType.reward,
      icon: '🎁',
    ));
  }

  // ── Schedule local notification (stub) ────────────────────────────────

  Future<void> scheduleLocalNotification({
    required String title,
    required String body,
    required Duration delay,
  }) async {
    // Real: FlutterLocalNotificationsPlugin().zonedSchedule(...)
    Future.delayed(delay, () {
      _push(AppNotification(
          title: title, body: body, type: NotificationType.gameEvent));
    });
  }

  void _push(AppNotification notification) {
    if (!_controller.isClosed) {
      _controller.add(notification);
    }
  }

  void dispose() {
    _controller.close();
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

enum NotificationType {
  turn,
  gameEvent,
  gameOver,
  tournamentMatch,
  tournamentFinals,
  reward,
}

class AppNotification {
  final String title;
  final String body;
  final NotificationType type;
  final String icon;
  final DateTime timestamp;

  AppNotification({
    required this.title,
    required this.body,
    required this.type,
    this.icon = '🔔',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ── In-app notification overlay widget ────────────────────────────────────────

class InAppNotificationOverlay extends StatefulWidget {
  final Widget child;
  const InAppNotificationOverlay({super.key, required this.child});

  @override
  State<InAppNotificationOverlay> createState() =>
      _InAppNotificationOverlayState();
}

class _InAppNotificationOverlayState extends State<InAppNotificationOverlay> {
  final List<AppNotification> _queue = [];
  StreamSubscription? _sub;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    _sub = NotificationService().notifications.listen(_onNotification);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onNotification(AppNotification n) {
    setState(() => _queue.add(n));
    if (!_showing) _showNext();
  }

  void _showNext() {
    if (_queue.isEmpty) {
      setState(() => _showing = false);
      return;
    }
    setState(() => _showing = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _queue.removeAt(0));
      _showNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_queue.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _NotificationBanner(notification: _queue.first),
          ),
      ],
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  final AppNotification notification;
  const _NotificationBanner({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF1A1035),
          border: Border.all(color: const Color(0xFF6C3CE1).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(notification.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    notification.body,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
