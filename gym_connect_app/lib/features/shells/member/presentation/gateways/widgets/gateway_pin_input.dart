import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class GatewayPinInput extends StatelessWidget {
  final int length;
  final TextEditingController controller;
  final Color accentColor;
  final ValueChanged<String>? onChanged;

  const GatewayPinInput({
    super.key,
    required this.length,
    required this.controller,
    required this.accentColor,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          length == 6 ? 'ENTER 6-DIGIT BANK OTP' : 'ENTER $length-DIGIT ACCOUNT MPIN',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: length,
          style: GoogleFonts.oswald(fontSize: 22, letterSpacing: 14, color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.background,
            hintText: '•' * length,
            hintStyle: GoogleFonts.oswald(fontSize: 22, letterSpacing: 14, color: AppColors.textSecondary),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accentColor, width: 1.5)),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
