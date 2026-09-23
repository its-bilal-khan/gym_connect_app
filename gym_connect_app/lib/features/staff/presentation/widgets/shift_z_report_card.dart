import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/staff_shift_repository.dart';

class ShiftZReportCard extends StatelessWidget {
  final ZReport report;
  final VoidCallback onDone;

  const ShiftZReportCard({
    super.key,
    required this.report,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.greenAccent),
          ),
          child: Column(
            children: [
              const Icon(Icons.receipt_long_rounded, color: Colors.greenAccent, size: 40),
              const SizedBox(height: 8),
              Text(
                'Z-REPORT GENERATED',
                style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Shift closed. Expected: PKR ${report.summary.expectedCashInDrawer.toInt()} • Counted: PKR ${report.actualCashCounted.toInt()}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Variance: ${report.cashVariance >= 0 ? "+" : ""}PKR ${report.cashVariance.toInt()}',
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: report.cashVariance == 0 ? Colors.greenAccent : Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onDone,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('DONE', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
