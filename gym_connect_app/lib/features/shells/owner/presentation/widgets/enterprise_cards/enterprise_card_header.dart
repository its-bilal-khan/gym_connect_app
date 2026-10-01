import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';

class EnterpriseCardHeader extends StatelessWidget {
  final IconData icon;
  final String moduleTag;
  final String badge;
  final bool isHighlight;
  final bool isHovered;
  final Color accent;
  final Widget? dragHandle;

  const EnterpriseCardHeader({
    super.key,
    required this.icon,
    required this.moduleTag,
    required this.badge,
    required this.isHighlight,
    required this.isHovered,
    required this.accent,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isHovered ? 0.25 : 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: accent.withValues(alpha: isHovered ? 0.8 : 0.4),
            ),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                moduleTag,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: accent,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'LIVE WORKSTATION',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isHighlight ? accent : accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accent),
          ),
          child: Text(
            badge,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.black : accent,
            ),
          ),
        ),
        if (dragHandle != null) ...[
          const SizedBox(width: 8),
          dragHandle!,
        ],
      ],
    );
  }
}
