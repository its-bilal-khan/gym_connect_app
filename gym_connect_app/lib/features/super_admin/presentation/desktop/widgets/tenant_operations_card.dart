import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/domain/models/user_role.dart';
import '../../../../auth/presentation/providers/auth_notifier.dart';
import '../../../domain/models/tenant_model.dart';
import '../../providers/tenant_providers.dart';

class TenantOperationsCard extends ConsumerWidget {
  final TenantModel tenant;

  const TenantOperationsCard({super.key, required this.tenant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(superAdminTenantsNotifierProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tenant.isActive ? AppColors.border : AppColors.error.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tenant.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tenant.primaryColor.withValues(alpha: 0.4)),
                ),
                child: Icon(Icons.fitness_center_rounded, color: tenant.primaryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tenant.name,
                            style: GoogleFonts.oswald(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTierBadge(),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${tenant.city}, Pakistan • /${tenant.slug} • ${tenant.contactPhone}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildStatusDropdown(context, notifier),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCapacityBar(),
              ),
              const SizedBox(width: 16),
              Text(
                'PKR ${tenant.monthlySaaSPKR.toStringAsFixed(0)}/mo',
                style: GoogleFonts.oswald(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureToggles(notifier),
          const SizedBox(height: 12),
          _buildActionButtons(context, ref),
        ],
      ),
    );
  }

  Widget _buildTierBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        tenant.tierBadgeLabel,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context, SuperAdminTenantsNotifier notifier) {
    final statusColor = tenant.statusBadgeColor;

    return PopupMenuButton<String>(
      onSelected: (newStatus) {
        final isActive = newStatus != 'suspended' && newStatus != 'cancelled';
        notifier.updateStatus(
          tenantId: tenant.id,
          newStatus: newStatus,
          isActive: isActive,
        );
      },
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      itemBuilder: (context) => [
        _buildPopupItem('active', 'Active (Operational)', const Color(0xFFCCFF00)),
        _buildPopupItem('trial', 'Trial Period', const Color(0xFF60A5FA)),
        _buildPopupItem('past_due', 'Past Due Billing', const Color(0xFFFBBF24)),
        _buildPopupItem('suspended', 'Suspend Tenant', const Color(0xFFEF4444)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
            ),
            const SizedBox(width: 6),
            Text(
              tenant.subscriptionStatus.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, color: statusColor, size: 16),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCapacityBar() {
    final ratio = (tenant.activeMembersCount / tenant.maxMembers).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Members: ${tenant.activeMembersCount}/${tenant.maxMembers}',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${(ratio * 100).toInt()}% Capacity',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(
              ratio > 0.9 ? AppColors.warning : AppColors.primary,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureToggles(SuperAdminTenantsNotifier notifier) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _buildFeatureChip(
          label: 'AI Coach',
          enabled: tenant.aiTrainerEnabled,
          onTap: () => notifier.toggleFeature(
            tenantId: tenant.id,
            featureKey: 'ai_trainer_enabled',
            enabled: !tenant.aiTrainerEnabled,
          ),
        ),
        _buildFeatureChip(
          label: 'POS Register',
          enabled: tenant.posEnabled,
          onTap: () => notifier.toggleFeature(
            tenantId: tenant.id,
            featureKey: 'pos_enabled',
            enabled: !tenant.posEnabled,
          ),
        ),
        _buildFeatureChip(
          label: 'ESP32 Turnstile',
          enabled: tenant.esp32GateEnabled,
          onTap: () => notifier.toggleFeature(
            tenantId: tenant.id,
            featureKey: 'esp32_gate_enabled',
            enabled: !tenant.esp32GateEnabled,
          ),
        ),
        _buildFeatureChip(
          label: 'Store & Khata',
          enabled: tenant.storeEnabled,
          onTap: () => notifier.toggleFeature(
            tenantId: tenant.id,
            featureKey: 'store_enabled',
            enabled: !tenant.storeEnabled,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChip({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary.withValues(alpha: 0.12) : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              enabled ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 13,
              color: enabled ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Simulating context for ${tenant.name}...'),
                  backgroundColor: AppColors.surface,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              ref.read(authNotifierProvider.notifier).switchActiveRole(UserRole.owner);
            },
            icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
            label: const Text('Inspect as Gym Owner'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
