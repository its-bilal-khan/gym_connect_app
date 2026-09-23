import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class GatewayOrderHeader extends StatelessWidget {
  final String gatewayName;
  final Color brandColor;
  final IconData brandIcon;
  final double amount;
  final String invoiceNumber;

  const GatewayOrderHeader({
    super.key,
    required this.gatewayName,
    required this.brandColor,
    required this.brandIcon,
    required this.amount,
    required this.invoiceNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: brandColor, radius: 16, child: Icon(brandIcon, color: Colors.white, size: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gatewayName, style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Secured by State Bank of Pakistan 256-Bit SSL', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, size: 12, color: Colors.greenAccent),
                    const SizedBox(width: 4),
                    Text('SECURE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.white12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MERCHANT: GYMCONNECT (PVT) LTD', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  Text('Invoice: $invoiceNumber', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary)),
                ],
              ),
              Text('PKR ${amount.toInt()}', style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
            ],
          ),
        ],
      ),
    );
  }
}
