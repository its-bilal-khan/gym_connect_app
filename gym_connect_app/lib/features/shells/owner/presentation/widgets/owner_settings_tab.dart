import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/info_banner_card.dart';
import '../../../../auth/domain/models/user_profile.dart';
import '../../../../payments/presentation/providers/payments_providers.dart';
import '../../../../payments/presentation/widgets/gym_payment_gateway_settings_sheet.dart';

class OwnerSettingsTab extends ConsumerWidget {
  final UserProfile profile;

  const OwnerSettingsTab({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final tenantId = profile.tenantId ?? '';
    final settingsAsync = ref.watch(tenantPaymentSettingsProvider(tenantId));
    final settings = settingsAsync.asData?.value;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GYM SETTINGS & MULTI-TENANT BRANDING',
              style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
            InfoBannerCard(icon: Icons.store_rounded, title: profile.tenantName, description: 'SaaS Pro Tier • Auto-renew active'),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => GymPaymentGatewaySettingsSheet.show(context, tenantId: tenantId, initialSettings: settings),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      radius: 20,
                      child: Icon(Icons.payment_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PAYMENT GATEWAYS & ACCOUNTS', style: GoogleFonts.oswald(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(
                            'Configure PayFast, EasyPaisa & Bank Transfer toggles',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
