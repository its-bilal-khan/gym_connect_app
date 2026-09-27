import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/shared/widgets/info_banner_card.dart';

class OwnerStaffAuditTab extends StatelessWidget {
  final UserProfile profile;

  const OwnerStaffAuditTab({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STAFF OVERSIGHT & AUDIT WATCHDOG',
              style: GoogleFonts.oswald(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            const InfoBannerCard(
              icon: Icons.shield_outlined,
              title: 'Anti-Theft Active',
              description: '0 voided receipts or deleted bills in 24 hours.',
            ),
            const SizedBox(height: 12),
            const InfoBannerCard(
              icon: Icons.point_of_sale_rounded,
              title: 'Shift 1 Cash Drawer',
              description: 'Opened at 06:00 AM • PKR 54,000 in cash collected.',
            ),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
