import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../membership/data/membership_repository.dart';
import '../../../shells/member/presentation/widgets/pay_dues_sheet.dart';

class UrgentDuesBanner extends ConsumerWidget {
  const UrgentDuesBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(pendingInvoiceProvider);
    final invoice = invoiceAsync.asData?.value;

    if (invoice == null || invoice.dueAmount <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MEMBERSHIP RENEWAL DUE', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber)),
                Text('PKR ${invoice.dueAmount.toInt()} pending • Pay to keep gate unlocked', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => PayDuesSheet.show(context),
            child: Text('PAY NOW', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
