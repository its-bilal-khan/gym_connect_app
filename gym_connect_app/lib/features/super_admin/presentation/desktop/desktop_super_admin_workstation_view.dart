import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../providers/tenant_providers.dart';
import 'widgets/exercise_video_studio_tab.dart';
import 'widgets/god_mode_audit_tab.dart';
import 'widgets/onboard_gym_tab.dart';
import 'widgets/saas_revenue_tab.dart';
import 'widgets/tenant_metric_header.dart';
import 'widgets/tenant_operations_card.dart';
import '../../../calculators/presentation/screens/calculators_hub_screen.dart';

class DesktopSuperAdminWorkstationView extends ConsumerStatefulWidget {
  final UserProfile profile;
  final int initialTabIndex;

  const DesktopSuperAdminWorkstationView({
    super.key,
    required this.profile,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<DesktopSuperAdminWorkstationView> createState() =>
      _DesktopSuperAdminWorkstationViewState();
}

class _DesktopSuperAdminWorkstationViewState
    extends ConsumerState<DesktopSuperAdminWorkstationView> {
  late int _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex;
    _restoreSavedTab();
  }

  Future<void> _restoreSavedTab() async {
    final storage = ref.read(secureStorageProvider);
    final saved = await storage.getActiveSubTab('super_admin');
    if (saved != null && mounted) {
      if (saved >= 0 && saved < _subTabs.length) {
        setState(() => _activeTab = saved);
      }
    }
  }

  void _onTabSelected(int index) {
    setState(() => _activeTab = index);
    ref.read(secureStorageProvider).saveActiveSubTab('super_admin', index);
    ref.read(secureStorageProvider).saveActiveNavIndex(index);
  }

  @override
  void didUpdateWidget(covariant DesktopSuperAdminWorkstationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _activeTab = widget.initialTabIndex;
      ref
          .read(secureStorageProvider)
          .saveActiveSubTab('super_admin', widget.initialTabIndex);
    }
  }

  static const _subTabs = [
    (title: 'TENANTS DIRECTORY & OPERATIONS', icon: Icons.business_rounded),
    (title: 'ONBOARD NEW GYM TENANT', icon: Icons.add_business_rounded),
    (title: 'EXERCISE & VIDEO STUDIO', icon: Icons.video_collection_rounded),
    (title: 'SAAS REVENUE & TIERS', icon: Icons.insights_rounded),
    (title: 'AUDIT & GOD MODE', icon: Icons.security_rounded),
    (title: 'FITNESS TOOLS', icon: Icons.calculate_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: switch (_activeTab) {
            0 => _buildTenantsDirectoryView(),
            1 => OnboardGymTab(onSuccess: () => _onTabSelected(0)),
            2 => const ExerciseVideoStudioTab(),
            3 => const SaasRevenueTab(),
            4 => const GodModeAuditTab(),
            5 => const CalculatorsHubScreen(),
            _ => _buildTenantsDirectoryView(),
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.hub_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SUPER ADMIN WORKSTATION',
                    style: GoogleFonts.oswald(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Platform Multi-Tenant Operations & SaaS Infrastructure',
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_subTabs.length, (i) {
                  final t = _subTabs[i];
                  final isSelected = _activeTab == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _onTabSelected(i),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              t.icon,
                              size: 14,
                              color: isSelected ? Colors.black : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              t.title,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantsDirectoryView() {
    final filteredTenants = ref.watch(filteredTenantsProvider);
    final statusFilter = ref.watch(tenantFilterStatusProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TenantMetricHeader(),
          const SizedBox(height: 20),
          _buildSearchAndFilters(statusFilter),
          const SizedBox(height: 18),
          if (filteredTenants.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    'No Gym Tenants match your search or filter',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 580,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.15,
              ),
              itemCount: filteredTenants.length,
              itemBuilder: (context, index) {
                return TenantOperationsCard(tenant: filteredTenants[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(String currentStatus) {
    const statuses = ['All', 'Active', 'Trial', 'Suspended'];

    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (val) =>
                ref.read(tenantSearchQueryProvider.notifier).setQuery(val),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search gym by name, city, or slug...',
              hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: statuses.map((s) {
            final isSelected = currentStatus == s;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(
                  s,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : Colors.white70,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                onSelected: (_) =>
                    ref.read(tenantFilterStatusProvider.notifier).setStatus(s),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
