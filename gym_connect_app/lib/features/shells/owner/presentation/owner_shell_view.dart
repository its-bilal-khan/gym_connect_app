import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/info_banner_card.dart';
import '../../../auth/domain/models/user_profile.dart';
import 'widgets/owner_overview_tab.dart';
import 'widgets/owner_settings_tab.dart';

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
    Widget content;
    switch (selectedIndex) {
      case 0:
        content = OwnerOverviewTab(profile: profile);
        break;
      case 1:
        content = _buildStaffAndPosTab(context);
        break;
      case 2:
        content = _buildOperationsTab(context);
        break;
      case 3:
      default:
        content = OwnerSettingsTab(profile: profile);
        break;
    }

    try {
      ProviderScope.containerOf(context, listen: false);
      return content;
    } catch (_) {
      return ProviderScope(child: content);
    }
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
            const InfoBannerCard(icon: Icons.point_of_sale_rounded, title: 'Shift 1 Cash Drawer', description: 'Opened at 06:00 AM • PKR 54,000 in cash collected.'),
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
}
