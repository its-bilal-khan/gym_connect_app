import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/gamification/domain/models/vision_ai_config.dart';
import 'package:gym_connect_app/features/super_admin/domain/models/tenant_model.dart';

/// Scope selector and master toggle switch for Vision AI Live Trainer configuration.
class VisionAiScopeSelector extends StatelessWidget {
  final String? selectedTenantId;
  final List<TenantModel> tenants;
  final VisionAiConfig config;
  final ValueChanged<String?> onTenantSelected;
  final ValueChanged<bool> onToggleLiveTrainer;
  final ValueChanged<bool> onToggleAllowOverride;

  const VisionAiScopeSelector({
    super.key,
    required this.selectedTenantId,
    required this.tenants,
    required this.config,
    required this.onTenantSelected,
    required this.onToggleLiveTrainer,
    required this.onToggleAllowOverride,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: selectedTenantId,
                  dropdownColor: AppColors.surface,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'CONFIGURATION SCOPE',
                    labelStyle: GoogleFonts.oswald(color: AppColors.textSecondary, letterSpacing: 0.8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('🌐 GLOBAL SYSTEM (ALL TENANTS)')),
                    ...tenants.map(
                      (t) => DropdownMenuItem(value: t.id, child: Text('🏢 ${t.name.toUpperCase()}')),
                    ),
                  ],
                  onChanged: onTenantSelected,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: accent,
            title: Text(
              'LIVE AI TRAINER MASTER ENGINE',
              style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.white),
            ),
            subtitle: Text(
              selectedTenantId == null
                  ? 'Global killswitch. If OFF, live AI camera button is hidden everywhere.'
                  : 'Tenant-level toggle for the selected gym franchise.',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
            value: config.isLiveTrainerEnabled,
            onChanged: onToggleLiveTrainer,
          ),
          if (selectedTenantId == null) ...[
            const Divider(color: AppColors.border, height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.amberAccent,
              title: Text(
                'ALLOW TENANT OVERRIDES (RULE 9)',
                style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.amberAccent),
              ),
              subtitle: Text(
                'Allow gym owners to calibrate squat depth, alert delays, and audio timings for their gym.',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
              value: config.allowTenantOverride,
              onChanged: onToggleAllowOverride,
            ),
          ],
        ],
      ),
      ),
    );
  }
}
