import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../../shared/widgets/primary_button.dart';

class PublicShellView extends StatelessWidget {
  final UserProfile profile;
  final int selectedIndex;

  const PublicShellView({
    super.key,
    required this.profile,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return _buildExploreTab(context);
      case 1:
        return _buildGuestPassTab(context);
      case 2:
      default:
        return _buildPlansTab(context);
    }
  }

  Widget _buildExploreTab(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'DISCOVER GYMS NEARBY',
              style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: accent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'TITAN FITNESS CLUB',
                          style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('1.2 km away', style: GoogleFonts.inter(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('DHA Phase 5 • Modern Strength & Cardio Equipment • 24/7 Gate Access', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  PrimaryButton(text: 'CLAIM FREE 24-HOUR PASS', icon: Icons.confirmation_number_rounded, onPressed: () {}),
                ],
              ),
            ),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestPassTab(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      bottom: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner_rounded, size: 100, color: AppColors.primaryAccent),
              const SizedBox(height: 14),
              Text('INSTANT 24-HOUR GUEST PASS', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text('Claim your zero-friction guest pass to unlock gate entry today.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              SizedBox(height: 110 + bottomInset),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlansTab(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SELECT MEMBERSHIP TIER', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            Text('Join Titan Fitness Club directly with instant gate activation.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
