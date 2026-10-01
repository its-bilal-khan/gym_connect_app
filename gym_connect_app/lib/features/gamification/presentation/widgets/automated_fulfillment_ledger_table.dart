import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/models.dart';

class AutomatedFulfillmentLedgerTable extends StatelessWidget {
  final List<MonthlyPodiumArchive> ledger;

  const AutomatedFulfillmentLedgerTable({super.key, required this.ledger});

  @override
  Widget build(BuildContext context) {
    if (ledger.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 6),
            Text('NO FULFILLMENT RECORDS YET', style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text('Automated Rs. 0 invoices and subscription extensions will appear here on the 1st of every month.',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ledger.length,
        separatorBuilder: (_, _) => Divider(color: AppColors.border, height: 1),
        itemBuilder: (context, index) {
          final item = ledger[index];
          final rankColor = item.podiumRank == 1 ? Colors.amber : (item.podiumRank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: rankColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text('#${item.podiumRank}', style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: rankColor)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.memberName ?? 'Champion Member', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text('${item.monthYear} • ${item.rewardTitle}', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(item.isFulfilled ? '✓ Auto-Fulfilled' : 'Pending',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: item.isFulfilled ? accent : Colors.amber)),
                    Text('Rs. 0 Invoice • +${item.rewardValue}d Sub', style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
