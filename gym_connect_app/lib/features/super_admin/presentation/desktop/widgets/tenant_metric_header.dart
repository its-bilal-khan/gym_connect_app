import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/tenant_providers.dart';

class TenantMetricHeader extends ConsumerWidget {
  const TenantMetricHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(globalSaaSMetricsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildMetricItem(
            label: 'TOTAL ONBOARDED GYMS',
            value: '${metrics.totalTenants}',
            accent: Colors.white,
            icon: Icons.apartment_rounded,
          ),
          _buildDivider(),
          _buildMetricItem(
            label: 'ACTIVE SAAS TENANTS',
            value: '${metrics.activeTenants}',
            accent: AppColors.primary,
            icon: Icons.check_circle_rounded,
          ),
          _buildDivider(),
          _buildMetricItem(
            label: 'IN TRIAL / PENDING',
            value: '${metrics.trialTenants}',
            accent: const Color(0xFF60A5FA),
            icon: Icons.timelapse_rounded,
          ),
          _buildDivider(),
          _buildMetricItem(
            label: 'SUSPENDED BRANCHES',
            value: '${metrics.suspendedTenants}',
            accent: AppColors.error,
            icon: Icons.block_rounded,
          ),
          _buildDivider(),
          _buildMetricItem(
            label: 'GLOBAL SAAS MRR',
            value: 'PKR ${(metrics.totalMonthlyMRRPKR / 1000).toStringAsFixed(0)}K',
            accent: AppColors.primary,
            icon: Icons.monetization_on_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color accent,
    required IconData icon,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 36,
      width: 1,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
