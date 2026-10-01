import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/models.dart';
import '../providers/owner_reward_config_provider.dart';
import 'automated_fulfillment_ledger_table.dart';

class OwnerRewardConfiguratorDialog extends ConsumerStatefulWidget {
  final String tenantId;

  const OwnerRewardConfiguratorDialog({super.key, required this.tenantId});

  static Future<void> show(BuildContext context, {required String tenantId}) => showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750, maxHeight: 680),
            child: OwnerRewardConfiguratorDialog(tenantId: tenantId),
          ),
        ),
      );

  @override
  ConsumerState<OwnerRewardConfiguratorDialog> createState() => _OwnerRewardConfiguratorDialogState();
}

class _OwnerRewardConfiguratorDialogState extends ConsumerState<OwnerRewardConfiguratorDialog> {
  late TextEditingController _r1Ctrl;
  late TextEditingController _r2Ctrl;
  late TextEditingController _r3Ctrl;
  late TextEditingController _minWorkoutsCtrl;

  @override
  void initState() {
    super.initState();
    final c = ref.read(ownerRewardConfigProvider).config;
    _r1Ctrl = TextEditingController(text: c.rank1Title);
    _r2Ctrl = TextEditingController(text: c.rank2Title);
    _r3Ctrl = TextEditingController(text: c.rank3Title);
    _minWorkoutsCtrl = TextEditingController(text: '${c.minMonthlyWorkoutsQualification}');
    Future.microtask(() => ref.read(ownerRewardConfigProvider.notifier).loadConfigAndLedger(widget.tenantId));
  }

  @override
  void dispose() {
    _r1Ctrl.dispose();
    _r2Ctrl.dispose();
    _r3Ctrl.dispose();
    _minWorkoutsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerRewardConfigProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: accent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PODIUM REWARD CONFIGURATOR & LEDGER', style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Customize monthly 1st, 2nd, 3rd prizes and automated fulfillment', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildField('Rank 1 Prize (Gold)', _r1Ctrl, Icons.military_tech_rounded, Colors.amber),
                  const SizedBox(height: 8),
                  _buildField('Rank 2 Prize (Silver)', _r2Ctrl, Icons.military_tech_rounded, const Color(0xFFC0C0C0)),
                  const SizedBox(height: 8),
                  _buildField('Rank 3 Prize (Bronze)', _r3Ctrl, Icons.military_tech_rounded, const Color(0xFFCD7F32)),
                  const SizedBox(height: 8),
                  _buildField('Min Monthly Workouts Qualification', _minWorkoutsCtrl, Icons.fitness_center_rounded, accent, isNumber: true),
                  const SizedBox(height: 16),
                  Text('AUTOMATED FULFILLMENT LEDGER', style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  AutomatedFulfillmentLedgerTable(ledger: state.ledger),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: state.isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: state.isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text('SAVE & SYNC TO MEMBER APP', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, Color color, {bool isNumber = false}) => TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: color, size: 16),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
        ),
      );

  void _save() async {
    final minW = int.tryParse(_minWorkoutsCtrl.text.trim()) ?? 18;
    final newConfig = TenantRewardConfig(
      rank1Title: _r1Ctrl.text.trim(),
      rank2Title: _r2Ctrl.text.trim(),
      rank3Title: _r3Ctrl.text.trim(),
      minMonthlyWorkoutsQualification: minW,
    );
    final success = await ref.read(ownerRewardConfigProvider.notifier).saveConfig(tenantId: widget.tenantId, newConfig: newConfig);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rewards & Rules updated successfully!')));
    }
  }
}
