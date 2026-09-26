import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme_presets.dart';
import '../../../../../core/theme/app_theme_provider.dart';
import '../../../../../core/theme/widgets/theme_color_switcher_dialog.dart';
import '../../../../../shared/widgets/info_banner_card.dart';
import '../../../../auth/domain/models/user_profile.dart';
import '../../../../payments/presentation/providers/payments_providers.dart';
import '../../../../payments/presentation/widgets/gym_payment_gateway_settings_sheet.dart';

class OwnerSettingsTab extends ConsumerWidget {
  final UserProfile profile;

  const OwnerSettingsTab({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final tenantId = profile.tenantId ?? '';
    final settingsAsync = ref.watch(tenantPaymentSettingsProvider(tenantId));
    final settings = settingsAsync.asData?.value;
    final themeState = ref.watch(appThemeNotifierProvider);

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
              onTap: () => ThemeColorSwitcherDialog.show(context),
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
                      backgroundColor: accent.withValues(alpha: 0.15),
                      radius: 20,
                      child: Icon(Icons.palette_rounded, color: accent, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'BRAND ACCENT COLOR & THEME',
                                style: GoogleFonts.oswald(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              if (themeState.isPermanentLocked) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: accent.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_rounded, size: 10, color: accent),
                                      const SizedBox(width: 3),
                                      Text(
                                        'LOCKED',
                                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: accent),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            themeState.isPermanentLocked
                                ? 'Locked to ${themeState.lockedPreset?.name ?? 'gym brand'}. Tap to view or request change.'
                                : 'Active: ${themeState.currentPreset.name}. Tap to switch or lock permanently.',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: AppThemePreset.values.map((p) {
                              final isSel = themeState.currentPreset == p;
                              return Container(
                                margin: const EdgeInsets.only(right: 6),
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: p.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel ? Colors.white : Colors.transparent,
                                    width: isSel ? 2 : 1,
                                  ),
                                  boxShadow: isSel
                                      ? [BoxShadow(color: p.color.withValues(alpha: 0.6), blurRadius: 4)]
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.tune_rounded, size: 18, color: accent),
                  ],
                ),
              ),
            ),
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
                      backgroundColor: accent.withValues(alpha: 0.15),
                      radius: 20,
                      child: Icon(Icons.payment_rounded, color: accent, size: 22),
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
                    Icon(Icons.tune_rounded, size: 18, color: accent),
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
