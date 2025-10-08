import 'package:flutter/material.dart';

enum PatientStatus { onTrack, watch, needsAttention }

class StatusChip extends StatelessWidget {
  final PatientStatus status;
  final EdgeInsets padding;
  const StatusChip(
      {super.key,
      required this.status,
      this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6)});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case PatientStatus.onTrack:
        return _build(
            'On Track', const Color(0xFFDFF5E4), const Color(0xFF1E8E3E));
      case PatientStatus.watch:
        return _build(
            'Watch', const Color(0xFFE8F0FE), const Color(0xFF1967D2));
      case PatientStatus.needsAttention:
        return _build('Needs Attention', const Color(0xFFFFE9D6),
            const Color(0xFFB06000));
    }
  }

  Widget _build(String label, Color bg, Color fg) => Container(
        padding: padding,
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
      );
}
