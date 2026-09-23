import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/staff_reception_repository.dart';

class StaffWalkInDialog extends ConsumerStatefulWidget {
  const StaffWalkInDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const StaffWalkInDialog(),
    );
  }

  @override
  ConsumerState<StaffWalkInDialog> createState() => _StaffWalkInDialogState();
}

class _StaffWalkInDialogState extends ConsumerState<StaffWalkInDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  GuestPassInfo? _generatedPass;
  bool _isIssuing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _issueGuestPass() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() => _isIssuing = true);

    final pass = await ref.read(staffReceptionRepositoryProvider).createWalkInGuestPass(
      guestName: name,
      guestPhone: phone,
    );

    if (!mounted) return;
    setState(() {
      _isIssuing = false;
      _generatedPass = pass;
    });
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('WALK-IN GUEST PASS', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Issue 24-hour single-entry pass & unlock gate', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              if (_generatedPass != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 40),
                      const SizedBox(height: 8),
                      Text('PASS CODE: ${_generatedPass!.passCode}', style: GoogleFonts.oswald(fontSize: 26, fontWeight: FontWeight.bold, color: accent, letterSpacing: 2)),
                      const SizedBox(height: 4),
                      Text(_generatedPass!.guestName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('Valid for 24 hours • Fee Collected: PKR 1,000', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('DONE', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                TextField(
                  controller: _nameController,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Guest Full Name',
                    labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Guest Mobile Phone',
                    labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isIssuing ? null : _issueGuestPass,
                  style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isIssuing
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text('COLLECT PKR 1,000 & ISSUE PASS', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
