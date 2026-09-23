import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/staff_reception_repository.dart';

class StaffCheckInDialog extends ConsumerStatefulWidget {
  const StaffCheckInDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const StaffCheckInDialog(),
    );
  }

  @override
  ConsumerState<StaffCheckInDialog> createState() => _StaffCheckInDialogState();
}

class _StaffCheckInDialogState extends ConsumerState<StaffCheckInDialog> {
  final TextEditingController _codeController = TextEditingController();
  CheckInResult? _result;
  bool _isChecking = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _processCheckIn() async {
    final query = _codeController.text.trim();
    if (query.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() => _isChecking = true);
    final res = await ref.read(staffReceptionRepositoryProvider).validateAndCheckIn(tokenOrPhone: query);
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _result = res;
    });
    if (res.isSuccess) {
      HapticFeedback.heavyImpact();
    }
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
                  Text('MEMBER CHECK-IN', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Scan QR or enter Token (#GC-XXXX), Phone, or Member ID', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                autofocus: true,
                style: GoogleFonts.oswald(fontSize: 18, color: AppColors.textPrimary, letterSpacing: 1),
                decoration: InputDecoration(
                  hintText: 'e.g. GC-9821 or 03001234567',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.cyanAccent),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryAccent),
                    onPressed: _processCheckIn,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
                onSubmitted: (_) => _processCheckIn(),
              ),
              const SizedBox(height: 16),
              if (_isChecking)
                const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
              else if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _result!.isSuccess ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _result!.isSuccess ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Icon(_result!.isSuccess ? Icons.verified_user_rounded : Icons.gpp_bad_rounded, color: _result!.isSuccess ? Colors.greenAccent : Colors.redAccent, size: 40),
                      const SizedBox(height: 8),
                      Text(_result!.memberName, style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(_result!.status, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _result!.isSuccess ? Colors.greenAccent : Colors.redAccent)),
                      const SizedBox(height: 6),
                      Text(_result!.message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              ElevatedButton(
                onPressed: _processCheckIn,
                style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('VERIFY & UNLOCK GATE', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
