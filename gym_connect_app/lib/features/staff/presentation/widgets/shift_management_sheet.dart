import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/staff/data/staff_shift_repository.dart';
import 'shift_z_report_card.dart';

class ShiftManagementSheet extends ConsumerStatefulWidget {
  const ShiftManagementSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ShiftManagementSheet(),
    );
  }

  @override
  ConsumerState<ShiftManagementSheet> createState() => _ShiftManagementSheetState();
}

class _ShiftManagementSheetState extends ConsumerState<ShiftManagementSheet> {
  final TextEditingController _cashCountedController = TextEditingController();
  final TextEditingController _pettyAmountController = TextEditingController();
  final TextEditingController _pettyDescController = TextEditingController();
  ZReport? _closedReport;
  bool _showPettyForm = false;

  @override
  void dispose() {
    _cashCountedController.dispose();
    _pettyAmountController.dispose();
    _pettyDescController.dispose();
    super.dispose();
  }

  Future<void> _submitPetty(ShiftSummary shift) async {
    final amt = double.tryParse(_pettyAmountController.text.trim()) ?? 0.0;
    final desc = _pettyDescController.text.trim();
    if (amt <= 0 || desc.isEmpty) return;

    await ref.read(staffShiftRepositoryProvider).recordPettyExpense(shiftId: shift.shiftId, amount: amt, category: 'Supplies', description: desc);
    ref.invalidate(activeShiftProvider);
    if (!mounted) return;
    setState(() {
      _showPettyForm = false;
      _pettyAmountController.clear();
      _pettyDescController.clear();
    });
  }

  Future<void> _closeShift(ShiftSummary shift) async {
    final counted = double.tryParse(_cashCountedController.text.trim()) ?? shift.expectedCashInDrawer;
    HapticFeedback.heavyImpact();
    final report = await ref.read(staffShiftRepositoryProvider).closeShiftAndGenerateZReport(summary: shift, actualCashCounted: counted);
    ref.invalidate(activeShiftProvider);
    if (!mounted) return;
    setState(() => _closedReport = report);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    final shiftAsync = ref.watch(activeShiftProvider);

    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SHIFT TALLY & Z-REPORT', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            if (_closedReport != null)
              ShiftZReportCard(report: _closedReport!, onDone: () => Navigator.pop(context))
            else
              shiftAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12))),
                data: (shift) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                      child: Column(
                        children: [
                          _row('Opening Float', 'PKR ${shift.openingCash.toInt()}'),
                          _row('Cash Sales', 'PKR ${shift.cashSales.toInt()}', color: Colors.greenAccent),
                          _row('Digital & JazzCash', 'PKR ${shift.digitalSales.toInt()}', color: Colors.cyanAccent),
                          _row('Petty Cash Spent', '- PKR ${shift.pettyCashSpent.toInt()}', color: Colors.redAccent),
                          const Divider(color: AppColors.border, height: 14),
                          _row('Expected Drawer Cash', 'PKR ${shift.expectedCashInDrawer.toInt()}', isBold: true, color: accent),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_showPettyForm) ...[
                      TextField(controller: _pettyAmountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Expense Amount (PKR)', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 8),
                      TextField(controller: _pettyDescController, decoration: InputDecoration(labelText: 'Reason (e.g. Ice / Mop / Water)', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: () => _submitPetty(shift), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('CONFIRM EXPENSE')),
                    ] else
                      OutlinedButton.icon(onPressed: () => setState(() => _showPettyForm = true), icon: const Icon(Icons.remove_circle_outline_rounded, size: 16), label: const Text('Log Petty Cash Expense'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.border))),
                    const SizedBox(height: 12),
                    TextField(controller: _cashCountedController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Actual Drawer Cash Counted (PKR)', hintText: '${shift.expectedCashInDrawer.toInt()}', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 14),
                    ElevatedButton(onPressed: () => _closeShift(shift), style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('CLOSE SHIFT & PRINT Z-REPORT', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
