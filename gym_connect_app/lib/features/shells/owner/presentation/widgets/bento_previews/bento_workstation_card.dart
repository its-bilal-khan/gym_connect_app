import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';

/// Bento-Box Workstation Card with a scaled-down, real-time live preview
/// of the actual module UI on the right side.
class BentoWorkstationCard extends StatefulWidget {
  final double width;
  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final bool isHighlight;
  final VoidCallback onTap;
  final Widget previewWidget;

  final String? moduleTag;
  final Widget? dragHandle;

  const BentoWorkstationCard({
    super.key,
    required this.width,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.isHighlight,
    required this.onTap,
    required this.previewWidget,
    this.moduleTag,
    this.dragHandle,
  });

  @override
  State<BentoWorkstationCard> createState() => _BentoWorkstationCardState();
}

class _BentoWorkstationCardState extends State<BentoWorkstationCard> {
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
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: 205,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isHovered ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? accent : accent.withValues(alpha: 0.85),
              width: isHovered ? 1.8 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isHovered ? 0.28 : 0.18),
                blurRadius: isHovered ? 20 : 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Content: Secondary Metadata (Expanded to fill remaining card space cleanly)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Icon + Badge + Optional Drag Handle
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: accent,
                          child: Icon(
                            widget.icon,
                            color: Colors.black,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: accent,
                              ),
                            ),
                            child: Text(
                              widget.badge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 9.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        if (widget.dragHandle != null) ...[
                          const Spacer(),
                          widget.dragHandle!,
                        ],
                      ],
                    ),

                    // Middle: Title & Subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.oswald(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10.0,
                            height: 1.25,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Bottom: Live telemetry status indicator
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: isHovered ? 0.9 : 0.6),
                                blurRadius: isHovered ? 6 : 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'LIVE WORKSTATION',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 9.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Right: Scaled-down Bento Mini Preview Frame (Compact, snug 335px width)
              _buildMiniPreviewFrame(context, accent, isHovered),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPreviewFrame(BuildContext context, Color accent, bool isHovered) {
    final effectiveTag = widget.moduleTag ?? 'TITAN // WORKSTATION';
    // Perfectly matches the 1024x492 canonical canvas proportions:
    // Viewport height: 161px (205 card height - 24 padding - 20 titlebar = 161).
    // Viewport width: 161 * (1024 / 492) = 335px.
    final availableWidth = widget.width - 24 - 14;
    final previewWidth = availableWidth >= 500
        ? 335.0
        : (availableWidth - 160.0).clamp(200.0, 335.0);

    return SizedBox(
      width: previewWidth,
      child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: isHovered ? 0.40 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: accent.withValues(alpha: isHovered ? 0.12 : 0.06),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          children: [
            // Mini Studio Window Titlebar
            Container(
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF16161B),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  // 3 OS Window Dots
                  Row(
                    children: [
                      Container(width: 5.0, height: 5.0, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF5F56))),
                      const SizedBox(width: 3.5),
                      Container(width: 5.0, height: 5.0, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFBD2E))),
                      const SizedBox(width: 3.5),
                      Container(width: 5.0, height: 5.0, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF27C93F))),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      effectiveTag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                      boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.8), blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),

            // Live Module UI Viewport: Crisp, responsive live preview
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.center,
                    child: IgnorePointer(
                      child: Transform.scale(
                        scale: 1.0,
                        alignment: Alignment.center,
                        child: widget.previewWidget,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
