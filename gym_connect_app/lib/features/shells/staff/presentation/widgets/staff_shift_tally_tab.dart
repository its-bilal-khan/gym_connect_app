import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/shared/widgets/action_card.dart';
import 'package:gym_connect_app/features/staff/data/staff_shift_repository.dart';
import 'package:gym_connect_app/features/staff/presentation/widgets/shift_management_sheet.dart';

class StaffShiftTallyTab extends ConsumerWidget {
  const StaffShiftTallyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final shiftAsync = ref.watch(activeShiftProvider);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SHIFT TALLY & Z-REPORT',
              style: GoogleFonts.oswald(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            shiftAsync.when(
              data: (shift) {
                return Column(
                  children: [
                    ActionCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'Current Shift Tally',
                      subtitle: 'Cash Drawer: Rs. ${shift.expectedCashInDrawer.toStringAsFixed(0)} • ${shift.totalInvoicesCount} Invoices Collected',
                      actionLabel: 'PRINT Z-REPORT',
                      onTap: () => ShiftManagementSheet.show(context),
                    ),
                    const SizedBox(height: 14),
                    _buildShiftStatsCard(shift),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primaryAccent),
                ),
              ),
              error: (err, _) => ActionCard(
                icon: Icons.receipt_long_rounded,
                title: 'Current Shift Tally',
                subtitle: 'Tap to initialize or tally current shift',
                actionLabel: 'OPEN TALLY',
                onTap: () => ShiftManagementSheet.show(context),
              ),
            ),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftStatsCard(ShiftSummary shift) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ACTIVE SHIFT METRICS', style: GoogleFonts.oswald(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primaryAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text('LIVE', style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRow('Staff on Register:', shift.staffName),
          const SizedBox(height: 6),
          _buildRow('Opening Float:', 'Rs. ${shift.openingCash.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          _buildRow('Cash Sales:', 'Rs. ${shift.cashSales.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          _buildRow('Digital / Online:', 'Rs. ${shift.digitalSales.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          _buildRow('Petty Cash Spent:', 'Rs. ${shift.pettyCashSpent.toStringAsFixed(0)}'),
          const Divider(color: Colors.white10, height: 16),
          _buildRow(
            'Expected Drawer Cash:',
            'Rs. ${shift.expectedCashInDrawer.toStringAsFixed(0)}',
            isBold: true,
            highlightColor: AppColors.primaryAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? highlightColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: highlightColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
