import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/complaint.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ComplaintStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: colors.foreground,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  ({Color background, Color foreground}) _colorsFor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.bekliyor:
        return (background: const Color(0x1AE8A33B), foreground: const Color(0xFF7A4A00));
      case ComplaintStatus.inceleniyor:
        return (background: const Color(0x1A1780CC), foreground: appBlue);
      case ComplaintStatus.onaylandi:
        return (background: const Color(0x1A1FA463), foreground: appWhatsApp);
      case ComplaintStatus.reddedildi:
        return (background: const Color(0x1AD64545), foreground: const Color(0xFFB42318));
      case ComplaintStatus.tamamlandi:
        return (background: const Color(0x1A103B2F), foreground: appPrimary);
    }
  }
}
