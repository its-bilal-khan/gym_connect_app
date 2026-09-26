import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/tenant_providers.dart';

class SaasRevenueTab extends ConsumerWidget {
  const SaasRevenueTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(globalSaaSMetricsProvider);
    final tenants = ref.watch(superAdminTenantsNotifierProvider).value ?? [];

    final annualARR = metrics.totalMonthlyMRRPKR * 12;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildRevenueCard(
                  title: 'ANNUAL RECURRING REVENUE (ARR)',
                  value: 'PKR ${(annualARR / 1000000).toStringAsFixed(2)}M',
                  subtext: 'Projected across ${metrics.activeTenants} active contracted gyms',
                  accent: AppColors.primary,
                  icon: Icons.auto_graph_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRevenueCard(
                  title: 'MONTHLY RECURRING REVENUE (MRR)',
                  value: 'PKR ${(metrics.totalMonthlyMRRPKR / 1000).toStringAsFixed(0)}K',
                  subtext: 'Recurring monthly billings collected via PayFast / 1Link',
                  accent: const Color(0xFF00F0FF),
                  icon: Icons.payments_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRevenueCard(
                  title: 'NETWORK CAPACITY ENROLLED',
                  value: '${metrics.totalMembersAcrossGyms} Members',
                  subtext: 'Across all gym branches in Pakistan',
                  accent: const Color(0xFFA855F7),
                  icon: Icons.people_alt_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'MULTI-BRANCH CITY DISTRIBUTION & HARDWARE CONNECTIVITY',
            style: GoogleFonts.oswald(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tenants.length,
              separatorBuilder: (_, _) => const Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, index) {
                final t = tenants[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: t.statusBadgeColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.name,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              '${t.city} • ${t.address}',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          t.tierBadgeLabel,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${t.activeMembersCount} / ${t.maxMembers} Members',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          t.esp32GateEnabled ? 'ESP32 Relay Online' : 'Manual Gate',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: t.esp32GateEnabled ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        'PKR ${t.monthlySaaSPKR.toStringAsFixed(0)}/mo',
                        style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard({
    required String title,
    required String value,
    required String subtext,
    required Color accent,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8),
              ),
              Icon(icon, color: accent, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.oswald(fontSize: 26, fontWeight: FontWeight.bold, color: accent),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
