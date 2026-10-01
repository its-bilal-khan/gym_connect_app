import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/gamification/domain/models/vision_ai_config.dart';
import 'package:gym_connect_app/features/gamification/presentation/providers/vision_ai_config_provider.dart';
import 'package:gym_connect_app/features/super_admin/presentation/providers/tenant_providers.dart';
import 'vision_ai_scope_selector.dart';
import 'vision_ai_slider_group.dart';

/// Desktop workstation for Super Admin to configure Vision AI thresholds, killswitches & overrides.
class SuperAdminVisionAiConfigurator extends ConsumerStatefulWidget {
  const SuperAdminVisionAiConfigurator({super.key});

  @override
  ConsumerState<SuperAdminVisionAiConfigurator> createState() =>
      _SuperAdminVisionAiConfiguratorState();
}

class _SuperAdminVisionAiConfiguratorState
    extends ConsumerState<SuperAdminVisionAiConfigurator> {
  String? _selectedTenantId;
  VisionAiConfig _localConfig = const VisionAiConfig();
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadConfigForScope(null);
      _isInitialized = true;
    }
  }

  Future<void> _loadConfigForScope(String? tenantId) async {
    final repo = ref.read(visionAiConfigRepositoryProvider);
    final fetched = await repo.fetchEffectiveConfig(tenantId);
    if (mounted) {
      setState(() {
        _selectedTenantId = tenantId;
        _localConfig = fetched;
      });
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    final repo = ref.read(visionAiConfigRepositoryProvider);
    bool ok;
    if (_selectedTenantId != null) {
      ok = await repo.updateTenantConfig(_selectedTenantId!, _localConfig);
    } else {
      ok = await repo.updateGlobalConfig(_localConfig, allowTenantOverride: _localConfig.allowTenantOverride);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ref.read(visionAiConfigProvider.notifier).setConfig(_localConfig);
      ref.invalidate(effectiveVisionAiConfigProvider(_selectedTenantId));
      ref.invalidate(effectiveVisionAiConfigProvider(null));
      ref.invalidate(currentTenantVisionAiConfigProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Vision AI live configuration saved!' : 'Failed to save configuration.'),
          backgroundColor: ok ? AppColors.surface : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenants = ref.watch(superAdminTenantsNotifierProvider).asData?.value ?? [];
    final accent = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(accent),
          const SizedBox(height: 20),
          VisionAiScopeSelector(
            selectedTenantId: _selectedTenantId,
            tenants: tenants,
            config: _localConfig,
            onTenantSelected: (tId) => _loadConfigForScope(tId),
            onToggleLiveTrainer: (v) => setState(() => _localConfig = _localConfig.copyWith(isLiveTrainerEnabled: v)),
            onToggleAllowOverride: (v) => setState(() => _localConfig = _localConfig.copyWith(allowTenantOverride: v)),
          ),
          const SizedBox(height: 16),
          VisionAiSliderGroup(
            config: _localConfig,
            onSquatDepthChanged: (v) => setState(() => _localConfig = _localConfig.copyWith(squatDepthAngle: v)),
            onPushupDepthChanged: (v) => setState(() => _localConfig = _localConfig.copyWith(pushupDepthAngle: v)),
            onBadPostureDelayChanged: (v) => setState(() => _localConfig = _localConfig.copyWith(badPostureTriggerMs: v)),
            onTtsCooldownChanged: (v) => setState(() => _localConfig = _localConfig.copyWith(ttsCooldownSeconds: v)),
            onMicroClipDurationChanged: (v) => setState(() => _localConfig = _localConfig.copyWith(microClipDurationSec: v)),
          ),
          const SizedBox(height: 20),
          _buildSaveButton(accent),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.psychology_alt_rounded, color: accent, size: 28),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VISION AI LIVE TRAINER CONFIGURATOR (RULE 9)',
              style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white),
            ),
            Text(
              'Manage biomechanics angle thresholds, audio coaching debounce & tenant override permissions.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton(Color accent) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveConfig,
        icon: _isSaving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : const Icon(Icons.check_circle_outline_rounded, size: 20),
        label: Text('SAVE VISION AI CONFIGURATION', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
