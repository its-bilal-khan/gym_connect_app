import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/info_banner_card.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../dashboard/presentation/widgets/metric_card.dart';

class OwnerShellView extends StatelessWidget {
  final UserProfile profile;
  final int selectedIndex;

  const OwnerShellView({
    super.key,
    required this.profile,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return _buildOverviewTab(context);
      case 1:
        return _buildStaffAndPosTab(context);
      case 2:
        return _buildOperationsTab(context);
      case 3:
      default:
        return _buildSettingsTab(context);
    }
  }

  Widget _buildOverviewTab(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'EXECUTIVE OVERVIEW',
                    style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('LIVE SYNC', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const MetricCard(title: 'Monthly Revenue', value: '\$18,420', icon: Icons.attach_money_rounded, subtitle: '+14.2% vs previous period'),
            const SizedBox(height: 12),
            const MetricCard(title: 'Active Members', value: '1,482', icon: Icons.people_alt_rounded, subtitle: '96.2% retention rate'),
            const SizedBox(height: 12),
            const MetricCard(title: 'Gate Check-Ins Today', value: '348', icon: Icons.door_sliding_rounded, subtitle: 'Peak: 6:00 PM - 8:30 PM'),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffAndPosTab(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('STAFF OVERSIGHT & AUDIT WATCHDOG', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            const InfoBannerCard(icon: Icons.shield_outlined, title: 'Anti-Theft Active', description: '0 voided receipts or deleted bills in 24 hours.'),
            const SizedBox(height: 12),
            const InfoBannerCard(icon: Icons.point_of_sale_rounded, title: 'Shift 1 Cash Drawer', description: 'Opened at 06:00 AM • \$540 in cash collected.'),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsTab(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HARDWARE & IOT GATE STATUS', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            const InfoBannerCard(icon: Icons.router_rounded, title: 'ESP32 Wi-Fi Relay', description: 'Connected (192.168.1.120) • Lock Armed'),
            const SizedBox(height: 12),
            const InfoBannerCard(icon: Icons.videocam_rounded, title: 'RTSP CCTV Security Stream', description: '4 Channels Active • RTSP Engine Ready'),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GYM SETTINGS & MULTI-TENANT BRANDING', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            InfoBannerCard(icon: Icons.store_rounded, title: profile.tenantName, description: 'SaaS Pro Tier • Auto-renew active'),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
