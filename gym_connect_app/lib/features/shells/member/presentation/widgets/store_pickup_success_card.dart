import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class StorePickupSuccessCard extends StatelessWidget {
  final String pickupCode;
  final VoidCallback onClose;

  const StorePickupSuccessCard({
    super.key,
    required this.pickupCode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              const Icon(Icons.qr_code_2_rounded, color: Colors.cyanAccent, size: 48),
              const SizedBox(height: 12),
              Text('PICKUP CODE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(pickupCode, style: GoogleFonts.oswald(fontSize: 34, fontWeight: FontWeight.bold, color: accent, letterSpacing: 3)),
              const SizedBox(height: 10),
              Text('Show this code at the Juice Bar / Front Desk to collect your items.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onClose,
          style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text('CLOSE', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
