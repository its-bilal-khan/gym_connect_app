import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../membership/data/membership_repository.dart';

class PaymentDueSummaryCard extends StatelessWidget {
  final PendingInvoiceInfo? invoice;
  final String dueAmountStr;
  final Color accent;

  const PaymentDueSummaryCard({
    super.key,
    required this.invoice,
    required this.dueAmountStr,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(invoice?.title ?? 'MONTHLY VIP MEMBERSHIP', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text('PKR $dueAmountStr', style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: accent)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.withValues(alpha: 0.4))),
            child: Text('DUE OCT 01', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}
