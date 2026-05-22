import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.status});

  final String label;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(status ?? label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.$2,
        ),
      ),
    );
  }

  (Color bg, Color fg) _colorsFor(String raw) {
    final s = raw.toUpperCase();
    if (s.contains('PENDING')) return (AppColors.warningBg, AppColors.warning);
    if (s.contains('CONFIRMED') || s.contains('ASSIGNED')) {
      return (AppColors.infoBg, AppColors.info);
    }
    if (s.contains('PROCESS')) return (const Color(0xFFFEF9C3), const Color(0xFFCA8A04));
    if (s.contains('READY') || s.contains('TRANSIT') || s.contains('OUT_FOR')) {
      return (AppColors.purpleBg, AppColors.purple);
    }
    if (s.contains('DELIVERED') || s.contains('COMPLETED') || s.contains('PAID')) {
      return (AppColors.successBg, AppColors.success);
    }
    if (s.contains('FAILED') || s.contains('CANCEL') || s.contains('REJECT')) {
      return (AppColors.destructiveBg, AppColors.destructive);
    }
    if (s.contains('ARRIVED')) return (const Color(0xFFCCFBF1), const Color(0xFF0D9488));
    return (AppColors.backgroundTertiary, AppColors.mutedForeground);
  }
}
