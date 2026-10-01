import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'enterprise_card_header.dart';

class EnterpriseWorkstationCard extends StatefulWidget {
  final double width;
  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final String moduleTag;
  final Widget? dragHandle;
  final VoidCallback onTap;
  final List<String> telemetryPills;
  final String actionText;
  final bool isHighlight;

  const EnterpriseWorkstationCard({
    super.key,
    required this.width,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.moduleTag,
    this.dragHandle,
    required this.onTap,
    this.telemetryPills = const [],
    this.actionText = 'OPEN WORKSTATION',
    this.isHighlight = false,
  });

  @override
  State<EnterpriseWorkstationCard> createState() =>
      _EnterpriseWorkstationCardState();
}

class _EnterpriseWorkstationCardState extends State<EnterpriseWorkstationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isHovered = _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.width,
          height: 205,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isHovered ? const Color(0xFF1C1C22) : const Color(0xFF141418),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? accent
                  : accent.withValues(alpha: widget.isHighlight ? 0.6 : 0.25),
              width: isHovered ? 1.6 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(
                    alpha: isHovered ? 0.22 : (widget.isHighlight ? 0.10 : 0.04)),
                blurRadius: isHovered ? 20 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EnterpriseCardHeader(
                icon: widget.icon,
                moduleTag: widget.moduleTag,
                badge: widget.badge,
                isHighlight: widget.isHighlight,
                isHovered: isHovered,
                accent: accent,
                dragHandle: widget.dragHandle,
              ),
              _buildBody(),
              _buildFooter(accent, isHovered),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.oswald(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          widget.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            height: 1.3,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(Color accent, bool isHovered) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: widget.telemetryPills.map((pill) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF09090B),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  pill,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isHovered ? accent : accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: isHovered ? 1.0 : 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.actionText,
                style: GoogleFonts.oswald(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isHovered ? Colors.black : accent,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 12, color: isHovered ? Colors.black : accent),
            ],
          ),
        ),
      ],
    );
  }
}
