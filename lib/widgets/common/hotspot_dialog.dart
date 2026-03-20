// lib/widgets/common/hotspot_dialog.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// Call this from HomeScreen to show the host/join dialog
void showHotspotDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.darkSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('📡', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text('Hotspot LAN Play',
              style: GoogleFonts.fredoka(
                  fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Play over local WiFi — no internet needed',
              style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _HotspotOption(
                  emoji: '👑',
                  label: 'Host Game',
                  subtitle: 'Create a server\nfor others to join',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/hotspot', extra: {'isHost': true});
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _HotspotOption(
                  emoji: '🎮',
                  label: 'Join Game',
                  subtitle: 'Enter host IP\nto connect',
                  color: AppColors.greenPlayer,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/hotspot', extra: {'isHost': false});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.darkCard,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Both devices must be on the same WiFi hotspot. '
                    'Host will share their IP or QR code.',
                    style: GoogleFonts.nunito(
                        fontSize: 11, color: Colors.white60),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _HotspotOption extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HotspotOption({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.fredoka(
                    fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.nunito(
                    fontSize: 11, color: Colors.white54),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
