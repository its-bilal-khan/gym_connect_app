import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/shared/widgets/info_banner_card.dart';

class OwnerOperationsTab extends StatelessWidget {
  final UserProfile profile;

  const OwnerOperationsTab({super.key, required this.profile});

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
              'HARDWARE & IOT GATE STATUS',
              style: GoogleFonts.oswald(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            const InfoBannerCard(
              icon: Icons.router_rounded,
              title: 'ESP32 Wi-Fi Relay',
              description: 'Connected (192.168.1.120) • Lock Armed',
            ),
            const SizedBox(height: 12),
            const InfoBannerCard(
              icon: Icons.videocam_rounded,
              title: 'RTSP CCTV Security Stream',
              description: '4 Channels Active • RTSP Engine Ready',
            ),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
