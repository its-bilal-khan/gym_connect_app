import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class GatePassQrPreview extends StatelessWidget {
  final String currentToken;
  final bool isUnlocking;
  final Color accent;

  const GatePassQrPreview({
    super.key,
    required this.currentToken,
    required this.isUnlocking,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 15),
                ],
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 160, color: Colors.black),
            ),
            if (isUnlocking)
              Container(
                width: 184,
                height: 184,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: accent),
                    const SizedBox(height: 10),
                    Text('UNLOCKING...', style: GoogleFonts.oswald(color: accent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'PASS TOKEN: $currentToken',
            style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: accent, letterSpacing: 1.5),
          ),
        ),
      ],
    );
  }
}
