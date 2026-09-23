import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class PaymentChannelFields extends StatelessWidget {
  final String method;
  final TextEditingController phoneController;
  final TextEditingController cardNumberController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;

  const PaymentChannelFields({
    super.key,
    required this.method,
    required this.phoneController,
    required this.cardNumberController,
    required this.expiryController,
    required this.cvvController,
  });

  @override
  Widget build(BuildContext context) {
    if (method == 'JazzCash' || method == 'EasyPaisa') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: '$method Registered Mobile Number',
              hintText: '03001234567',
              prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            method == 'JazzCash'
                ? '⚡ An MPIN verification prompt will be sent to your mobile phone.'
                : '⚡ Authorize the transaction via EasyPaisa push notification.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return Column(
      children: [
        TextField(
          controller: cardNumberController,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, letterSpacing: 1.5),
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: '4242 4242 4242 4242',
            prefixIcon: const Icon(Icons.credit_card_rounded, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: expiryController,
                keyboardType: TextInputType.datetime,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Expiry (MM/YY)',
                  hintText: '12/28',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: cvvController,
                keyboardType: TextInputType.number,
                obscureText: true,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'CVV / CVC',
                  hintText: '•••',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
