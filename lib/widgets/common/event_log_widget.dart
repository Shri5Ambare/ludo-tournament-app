// lib/widgets/common/event_log_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class EventLogWidget extends StatelessWidget {
  final List<String> events;
  const EventLogWidget({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox();
    final recent = events.reversed.take(3).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: recent.asMap().entries.map((e) {
          final opacity = e.key == 0 ? 1.0 : (e.key == 1 ? 0.6 : 0.35);
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              e.value,
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: Colors.white.withValues(alpha: opacity),
                fontStyle:
                    e.key > 0 ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }
}
