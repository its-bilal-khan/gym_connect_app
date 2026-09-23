import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class ManualBankDetailsCard extends StatelessWidget {
  final String? easypaisaNumber;
  final String? bankDetails;
  final double amount;

  const ManualBankDetailsCard({
    super.key,
    required this.easypaisaNumber,
    required this.bankDetails,
    required this.amount,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard', style: GoogleFonts.inter(fontSize: 12)),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveEasypaisa = (easypaisaNumber != null && easypaisaNumber!.trim().isNotEmpty)
        ? easypaisaNumber!
        : '0300-1234567 (Titan Fitness)';
    final effectiveBank = (bankDetails != null && bankDetails!.trim().isNotEmpty)
        ? bankDetails!
        : 'Meezan Bank | IBAN: PK64MEZN0001234567890123 | Title: Titan Fitness Club';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIRECT BANK & WALLET TRANSFER',
                      style: GoogleFonts.oswald(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Transfer PKR ${amount.toInt()} using details below',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailTile(
            context,
            icon: Icons.phone_android_rounded,
            iconColor: const Color(0xFF00A859),
            title: 'EasyPaisa Account',
            value: effectiveEasypaisa,
            onCopy: () => _copyToClipboard(context, effectiveEasypaisa, 'EasyPaisa Number'),
          ),
          const SizedBox(height: 12),
          _buildDetailTile(
            context,
            icon: Icons.account_balance_wallet_rounded,
            iconColor: Colors.blueAccent,
            title: 'Gym Bank Account (IBAN)',
            value: effectiveBank,
            onCopy: () => _copyToClipboard(context, effectiveBank, 'Bank Details'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'After completing the transfer, take a clear screenshot of the transaction receipt and upload it below.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withValues(alpha: 0.15),
            radius: 16,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
            tooltip: 'Copy',
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}
