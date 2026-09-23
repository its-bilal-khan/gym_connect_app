import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/payments_repository.dart';
import '../../domain/models/tenant_payment_settings.dart';
import '../providers/payments_providers.dart';

class GymPaymentGatewaySettingsSheet extends ConsumerStatefulWidget {
  final String tenantId;
  final TenantPaymentSettings? initialSettings;

  const GymPaymentGatewaySettingsSheet({
    super.key,
    required this.tenantId,
    this.initialSettings,
  });

  static Future<void> show(
    BuildContext context, {
    required String tenantId,
    TenantPaymentSettings? initialSettings,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GymPaymentGatewaySettingsSheet(
        tenantId: tenantId,
        initialSettings: initialSettings,
      ),
    );
  }

  @override
  ConsumerState<GymPaymentGatewaySettingsSheet> createState() => _GymPaymentGatewaySettingsSheetState();
}

class _GymPaymentGatewaySettingsSheetState extends ConsumerState<GymPaymentGatewaySettingsSheet> {
  late bool _payfastEnabled;
  late bool _manualEnabled;
  late TextEditingController _easypaisaController;
  late TextEditingController _bankController;
  bool _isSaving = false;
  bool _isUserEditing = false;

  @override
  void initState() {
    super.initState();
    _payfastEnabled = widget.initialSettings?.isPayfastEnabled ?? false;
    _manualEnabled = widget.initialSettings?.isManualPaymentEnabled ?? false;
    _easypaisaController = TextEditingController(text: widget.initialSettings?.manualEasypaisaNumber ?? '');
    _bankController = TextEditingController(text: widget.initialSettings?.manualBankDetails ?? '');
  }

  @override
  void dispose() {
    _easypaisaController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final repo = ref.read(paymentsRepositoryProvider);

    final success = await repo.updateTenantPaymentConfig(
      tenantId: widget.tenantId,
      isPayfastEnabled: _payfastEnabled,
      isManualPaymentEnabled: _manualEnabled,
      manualEasypaisaNumber: _easypaisaController.text.trim(),
      manualBankDetails: _bankController.text.trim(),
    );

    ref.invalidate(tenantPaymentSettingsProvider(widget.tenantId));
    ref.invalidate(tenantPaymentSettingsProvider(''));
    ref.invalidate(currentGymPaymentSettingsProvider);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment configuration updated successfully!', style: GoogleFonts.inter(fontSize: 12)),
          backgroundColor: Colors.green.shade800,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update payment settings', style: GoogleFonts.inter(fontSize: 12)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tenantPaymentSettingsProvider(widget.tenantId), (prev, next) {
      final s = next.asData?.value;
      if (s != null && !_isUserEditing && mounted) {
        setState(() {
          _payfastEnabled = s.isPayfastEnabled;
          _manualEnabled = s.isManualPaymentEnabled;
          if (_easypaisaController.text.isEmpty && s.manualEasypaisaNumber != null) {
            _easypaisaController.text = s.manualEasypaisaNumber!;
          }
          if (_bankController.text.isEmpty && s.manualBankDetails != null) {
            _bankController.text = s.manualBankDetails!;
          }
        });
      }
    });

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PAYMENT GATEWAY CONFIGURATION', style: GoogleFonts.oswald(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white70), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            _buildSwitchTile('PayFast Gateway (Direct Cards & Wallets)', 'Enable automated digital PayFast checkout for members', _payfastEnabled, (val) => setState(() {
                  _payfastEnabled = val;
                  _isUserEditing = true;
                })),
            const SizedBox(height: 8),
            _buildSwitchTile('Manual Screenshot Method (Proof-of-Payment)', 'Allow members to transfer via EasyPaisa/Bank and upload receipts', _manualEnabled, (val) => setState(() {
                  _manualEnabled = val;
                  _isUserEditing = true;
                })),
            if (_manualEnabled) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _easypaisaController,
                onChanged: (_) => _isUserEditing = true,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'EasyPaisa Account Number / Title',
                  labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bankController,
                onChanged: (_) => _isUserEditing = true,
                maxLines: 2,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Bank Account Details (Bank Name, IBAN, Account Title)',
                  labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text('SAVE PAYMENT CONFIGURATION', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        value: value,
        activeThumbColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}
