import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/user_role.dart';

class RoleSwitcherSheet extends StatelessWidget {
  final UserRole activeRole;
  final ValueChanged<UserRole> onSelectRole;

  const RoleSwitcherSheet({
    super.key,
    required this.activeRole,
    required this.onSelectRole,
  });

  static const _roles = [
    (role: UserRole.owner, title: 'Gym Owner & Admin', desc: 'Financials, analytics, cameras & anti-theft.'),
    (role: UserRole.staff, title: 'Reception & POS Desk', desc: 'Check-ins, fee collections & shift reports.'),
    (role: UserRole.member, title: 'VIP Member Portal', desc: 'Dynamic QR pass & AI trainer routine.'),
    (role: UserRole.publicUser, title: 'Public Marketplace', desc: 'Explore gyms & free guest pass.'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, color: accent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ROLE-SWITCHING ENGINE',
                      style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Select a view layout to preview or execute operations in that mode.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ..._roles.map((item) {
                final isCurrent = item.role == activeRole;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        final selectedRole = item.role;
                        Navigator.of(context).pop();
                        onSelectRole(selectedRole);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrent ? accent.withValues(alpha: 0.12) : AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isCurrent ? accent : AppColors.border, width: isCurrent ? 1.5 : 1.0),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isCurrent ? accent : AppColors.surface,
                              child: Icon(item.role.icon, color: isCurrent ? Colors.black : AppColors.textPrimary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: isCurrent ? accent : AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(item.desc, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            if (isCurrent) Icon(Icons.check_circle_rounded, color: accent, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
