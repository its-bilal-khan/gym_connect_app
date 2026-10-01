import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/system_feature_toggle_repository.dart';
import '../../domain/models/system_feature_flags.dart';
import 'super_admin_feature_tile.dart';

/// Modal sheet for Super Admin to toggle features globally and set allow_tenant_override.
class SuperAdminFeatureFlagsSheet extends ConsumerStatefulWidget {
  final String? tenantId;

  const SuperAdminFeatureFlagsSheet({super.key, this.tenantId});

  static Future<void> show(BuildContext context, {String? tenantId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SuperAdminFeatureFlagsSheet(tenantId: tenantId),
    );
  }

  @override
  ConsumerState<SuperAdminFeatureFlagsSheet> createState() =>
      _SuperAdminFeatureFlagsSheetState();
}

class _SuperAdminFeatureFlagsSheetState
    extends ConsumerState<SuperAdminFeatureFlagsSheet> {
  late SystemFeatureFlags _flags;
  bool _isLoading = true;

  static const _modules = [
    ('ai_workouts', 'AI WORKOUTS ENGINE (PHASE 2)', 'Static 90-day master routine cloning, Silent BMI routing & injury substitution.', Icons.psychology_rounded),
    ('gamification', 'GAMIFICATION & ANTI-CHEAT (PHASE 1)', 'Daily activity point rewards, monthly resets, streak freezes & leaderboards.', Icons.military_tech_rounded),
    ('clinical_tools', 'CLINICAL TOOLS & CALCULATORS', 'Google-style BMI calculator, reactive calorie & macro nutrition engines.', Icons.calculate_rounded),
    ('diet_logs', 'DIET LOGS & NUTRITION TRACKING', 'Daily food logging, micro/macro tracking, and calorie ledger.', Icons.restaurant_menu_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadFlags();
  }

  Future<void> _loadFlags() async {
    final repo = ref.read(systemFeatureToggleRepositoryProvider);
    final flags = await repo.fetchEffectiveFeatureFlags(widget.tenantId);
    if (mounted) {
      setState(() {
        _flags = flags;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateFlag(String key, bool enabled, bool allowOverride) async {
    final repo = ref.read(systemFeatureToggleRepositoryProvider);
    if (widget.tenantId != null) {
      await repo.setTenantFeatureFlag(
        widget.tenantId!,
        key,
        enabled,
        allowTenantOverride: allowOverride,
      );
    } else {
      await repo.setGlobalFeatureFlag(
        key,
        enabled,
        allowTenantOverride: allowOverride,
      );
    }
    ref.invalidate(effectiveFeatureFlagsProvider(widget.tenantId));
    ref.invalidate(effectiveFeatureFlagsProvider(null));
    await _loadFlags();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView(
                children: _modules.map((m) {
                  final enabled = _flags.isEnabled(m.$1);
                  final override = _flags.canTenantOverride(m.$1);
                  return SuperAdminFeatureTile(
                    title: m.$2,
                    description: m.$3,
                    icon: m.$4,
                    isEnabled: enabled,
                    allowTenantOverride: override,
                    onToggleEnabled: (v) => _updateFlag(m.$1, v, override),
                    onToggleOverride: (v) => _updateFlag(m.$1, enabled, v),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amberAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.tune_rounded, color: Colors.amberAccent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.tenantId != null
                    ? 'TENANT FEATURE OVERRIDES (RULE 9)'
                    : 'GLOBAL MASTER FEATURE TOGGLES (RULE 9)',
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'Super Admin supremacy & allow_tenant_override policy enforcement',
                style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
