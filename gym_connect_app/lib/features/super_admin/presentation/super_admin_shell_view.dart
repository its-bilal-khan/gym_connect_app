import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/domain/models/user_profile.dart';
import 'desktop/widgets/god_mode_audit_tab.dart';
import 'desktop/widgets/onboard_gym_tab.dart';
import 'desktop/widgets/saas_revenue_tab.dart';
import 'desktop/widgets/tenant_operations_card.dart';
import 'providers/tenant_providers.dart';

class SuperAdminShellView extends ConsumerStatefulWidget {
  final UserProfile profile;
  final int selectedIndex;

  const SuperAdminShellView({
    super.key,
    required this.profile,
    this.selectedIndex = 0,
  });

  @override
  ConsumerState<SuperAdminShellView> createState() => _SuperAdminShellViewState();
}

class _SuperAdminShellViewState extends ConsumerState<SuperAdminShellView> {
  late int _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant SuperAdminShellView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _activeTab = widget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_activeTab) {
      0 => _buildMobileTenantsList(),
      1 => OnboardGymTab(onSuccess: () => setState(() => _activeTab = 0)),
      2 => const SaasRevenueTab(),
      3 => const GodModeAuditTab(),
      _ => _buildMobileTenantsList(),
    };
  }

  Widget _buildMobileTenantsList() {
    final filteredTenants = ref.watch(filteredTenantsProvider);
    final metrics = ref.watch(globalSaaSMetricsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL GYMS', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                    Text('${metrics.totalTenants}', style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ACTIVE SAAS', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                    Text('${metrics.activeTenants}', style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SAAS MRR', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                    Text('PKR ${(metrics.totalMonthlyMRRPKR / 1000).toStringAsFixed(0)}K', style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (val) => ref.read(tenantSearchQueryProvider.notifier).setQuery(val),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search gym or city...',
              hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredTenants.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return TenantOperationsCard(tenant: filteredTenants[index]);
            },
          ),
        ],
      ),
    );
  }
}
