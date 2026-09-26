import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/gym_member.dart';

/// Gym Member Card Widget that strictly mimics a physical, slim, vertical Plastic ID Badge.
/// 
/// Enhanced with enterprise-grade interactive depth:
/// - Smooth 250ms ease-in-out hover transition with subtle scale(1.01) lift
/// - Soft, elegant drop shadow (white with 3% opacity) on hover with zero flashy neon glows
/// - Primary surface pure #18181B with a barely perceptible 2% max tier radial aura behind the avatar
/// - Professional alert red (#EF4444) for overdue payments and expirations
/// - Mathematically centered vertical hierarchy with physical lanyard cutout and footer barcode
class MemberGridCard extends StatefulWidget {
  final GymMember member;
  final bool showDeepInsights;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageCredentials;
  final VoidCallback onToggleFreeze;
  final VoidCallback onSendReminder;

  const MemberGridCard({
    super.key,
    required this.member,
    required this.showDeepInsights,
    required this.onEdit,
    required this.onDelete,
    required this.onManageCredentials,
    required this.onToggleFreeze,
    required this.onSendReminder,
  });

  @override
  State<MemberGridCard> createState() => _MemberGridCardState();
}

class _MemberGridCardState extends State<MemberGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isExp = widget.member.isExpired;

    // 1. Resolve Tier Color & Label
    Color tierColor;
    String tierLabel;

    final planLower = widget.member.planName.toLowerCase();
    if (planLower.contains('vip') || planLower.contains('annual') || planLower.contains('gold')) {
      tierColor = const Color(0xFFFFC107); // Gold VIP
      tierLabel = 'ANNUAL VIP';
    } else if (planLower.contains('quarter') || planLower.contains('shred') || planLower.contains('silver')) {
      tierColor = const Color(0xFF00E5FF); // Electric Cyan
      tierLabel = 'QUARTERLY PASS';
    } else if (planLower.contains('semi') || planLower.contains('pro')) {
      tierColor = const Color(0xFFB388FF); // Lavender Pro
      tierLabel = 'PRO MEMBERSHIP';
    } else {
      tierColor = accent; // Tenant active dynamic accent
      tierLabel = widget.member.planName.toUpperCase();
    }

    final effectiveTopBorderColor = isExp
        ? const Color(0xFFEF4444).withValues(alpha: 0.85) // Alert Red #EF4444
        : (widget.member.isExpiringSoon
            ? Colors.orangeAccent.withValues(alpha: 0.85)
            : tierColor);

    return Center(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onEdit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            transform: Matrix4.diagonal3Values(_isHovered ? 1.01 : 1.0, _isHovered ? 1.01 : 1.0, 1.0),
            transformAlignment: Alignment.center,
            width: 260,
            height: 420,
            decoration: BoxDecoration(
              color: AppColors.surface, // Pure #18181B surface
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered ? const Color(0xFF52525B) : const Color(0xFF3F3F46), // Subtle, zero neon glow
                width: 3.0,
              ),
              boxShadow: [
                // Base physical card elevation shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isHovered ? 0.65 : 0.50),
                  blurRadius: _isHovered ? 24 : 18,
                  offset: Offset(0, _isHovered ? 10 : 7),
                ),
                // Subtle, soft white ambient glow (strictly rgba(255, 255, 255, 0.03)) on hover
                if (_isHovered)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.03),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                children: [
                  // Subtle 2px Top-Border Tier Indicator
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2.0,
                      color: effectiveTopBorderColor,
                    ),
                  ),

                  // Barely perceptible tier-based radial background aura behind avatar (locked to max 2% opacity)
                  Positioned(
                    top: 45,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              tierColor.withValues(alpha: 0.02), // Strictly 2% max opacity
                              Colors.transparent,
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Centered ID Badge Content (Strict vertical portrait hierarchy)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. The Lanyard Hole Cutout (Pill-shaped #09090B with inner shadow)
                        Container(
                          width: 44,
                          height: 7,
                          decoration: BoxDecoration(
                            color: const Color(0xFF09090B),
                            borderRadius: BorderRadius.circular(3.5),
                            border: Border.all(color: const Color(0xFF27272A), width: 1.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.9),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 2. Gym Name / Brand Header & Discreet Action Menu (Full Width Separated)
                        SizedBox(
                          width: double.infinity,
                          height: 26,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Mathematically centered brand title
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fitness_center_rounded, size: 13, color: accent),
                                    const SizedBox(width: 5),
                                    Text(
                                      'GYMCONNECT',
                                      style: GoogleFonts.oswald(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2.0,
                                        color: const Color(0xFFA1A1AA),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Discreet action menu pinned to the far right edge of the card
                              Positioned(
                                right: -4,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: _buildActionsMenu(context, accent),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 3. Large Circular Avatar (Center-aligned)
                        Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF131316),
                          border: Border.all(color: const Color(0xFF27272A), width: 2.0),
                        ),
                        child: ClipOval(
                          child: widget.member.avatarUrl != null && widget.member.avatarUrl!.isNotEmpty
                              ? Image.network(
                                  widget.member.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
                                )
                              : _buildAvatarFallback(),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 4. Member Name (Oswald Font)
                      Text(
                        widget.member.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // 5. Member ID (Monospace Badge)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131316),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFF27272A), width: 1.0),
                        ),
                        child: Text(
                          widget.member.memberCode,
                          style: GoogleFonts.robotoMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: const Color(0xFFA1A1AA),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 6. Minimalist Status (Tiny elegant pill badges & minimal text lines)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Tiny Status Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (widget.member.isFrozen
                                      ? Colors.cyanAccent
                                      : (isExp ? const Color(0xFFEF4444) : Colors.greenAccent))
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: (widget.member.isFrozen
                                        ? Colors.cyanAccent
                                        : (isExp ? const Color(0xFFEF4444) : Colors.greenAccent))
                                    .withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: widget.member.isFrozen
                                        ? Colors.cyanAccent
                                        : (isExp ? const Color(0xFFEF4444) : Colors.greenAccent),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.member.statusDisplay.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: widget.member.isFrozen
                                        ? Colors.cyanAccent
                                        : (isExp ? const Color(0xFFEF4444) : Colors.greenAccent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Tiny Tier Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tierColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: tierColor.withValues(alpha: 0.25), width: 0.8),
                            ),
                            child: Text(
                              tierLabel,
                              style: GoogleFonts.oswald(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                                color: tierColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Minimal Text Line with Professional Alert Red (#EF4444) for Overdue/Expired
                      Center(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Exp: ${widget.member.expiryDate.year}-${widget.member.expiryDate.month.toString().padLeft(2, '0')}-${widget.member.expiryDate.day.toString().padLeft(2, '0')}',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: isExp ? const Color(0xFFEF4444) : const Color(0xFFA1A1AA),
                                ),
                              ),
                              TextSpan(
                                text: widget.member.duesAmount > 0
                                    ? ' • PKR ${widget.member.duesAmount.toStringAsFixed(0)} DUE'
                                    : ' • PAID',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: widget.member.duesAmount > 0
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFA1A1AA),
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      if (widget.showDeepInsights) ...[
                        const SizedBox(height: 3),
                        Center(
                          child: Text(
                            '🔥 ${widget.member.currentStreakDays}D Streak • ${widget.member.assignedProtocol}',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: const Color(0xFFA1A1AA),
                            ),
                          ),
                        ),
                      ],

                      const Spacer(),

                      // 7. Footer Scan Area (Realistic barcode at absolute bottom)
                      SizedBox(
                        height: 28,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _BarcodeStripePainter(code: widget.member.memberCode),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'RFID PASS • ${widget.member.memberCode}',
                          style: GoogleFonts.robotoMono(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                            color: const Color(0xFFA1A1AA),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildActionsMenu(BuildContext context, Color accent) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFF1E1E22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF27272A)),
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Actions',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        icon: const Icon(Icons.more_vert_rounded, size: 16, color: Color(0xFFA1A1AA)),
        onSelected: (val) {
          if (val == 'credentials') widget.onManageCredentials();
          if (val == 'freeze') widget.onToggleFreeze();
          if (val == 'edit') widget.onEdit();
          if (val == 'whatsapp') widget.onSendReminder();
          if (val == 'delete') widget.onDelete();
        },
        itemBuilder: (ctx) => [
          _buildPopupMenuItem(
            'credentials',
            Icons.key_rounded,
            'Login Credentials',
            accent,
          ),
          _buildPopupMenuItem(
            'freeze',
            widget.member.isFrozen ? Icons.play_arrow_rounded : Icons.pause_rounded,
            widget.member.isFrozen ? 'Unfreeze Pass' : 'Freeze Pass (Leave)',
            widget.member.isFrozen ? Colors.greenAccent : Colors.cyanAccent,
          ),
          _buildPopupMenuItem(
            'edit',
            Icons.edit_rounded,
            'Edit Details',
            Colors.white,
          ),
          if (widget.member.isExpiringSoon || widget.member.duesAmount > 0)
            _buildPopupMenuItem(
              'whatsapp',
              Icons.chat_bubble_outline_rounded,
              'WhatsApp Renewal Alert',
              Colors.greenAccent,
            ),
          const PopupMenuDivider(height: 1),
          _buildPopupMenuItem(
            'delete',
            Icons.delete_outline_rounded,
            'Remove Member',
            const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Center(
      child: Text(
        widget.member.fullName.isNotEmpty ? widget.member.fullName[0].toUpperCase() : 'M',
        style: GoogleFonts.oswald(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFFFFFF),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      height: 38,
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws authentic barcode stripes in soft grey (#A1A1AA) with subtle opacity
class _BarcodeStripePainter extends CustomPainter {
  final String code;

  const _BarcodeStripePainter({required this.code});

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite || size.width <= 0 || !size.height.isFinite || size.height <= 0) {
      return;
    }
    final paint = Paint()
      ..color = const Color(0xFFA1A1AA).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final hash = code.hashCode.abs();
    const stripeCount = 32;
    final stripeWidth = size.width / (stripeCount * 1.5);

    double currentX = 0;
    for (int i = 0; i < stripeCount; i++) {
      final isThick = ((hash >> (i % 30)) & 1) == 1;
      final w = isThick ? stripeWidth * 1.5 : stripeWidth * 0.75;
      canvas.drawRect(Rect.fromLTWH(currentX, 0, w, size.height), paint);
      currentX += w + (isThick ? stripeWidth * 0.8 : stripeWidth * 0.55);
      if (currentX >= size.width) break;
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodeStripePainter oldDelegate) => oldDelegate.code != code;
}
