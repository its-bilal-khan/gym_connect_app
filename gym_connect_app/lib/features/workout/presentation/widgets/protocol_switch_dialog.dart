import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class ProtocolSwitchDialog extends StatelessWidget {
  final String selectedBodyType;
  final VoidCallback onConfirm;

  const ProtocolSwitchDialog({
    super.key,
    required this.selectedBodyType,
    required this.onConfirm,
  });

  static Future<void> show(BuildContext context, {required String selectedBodyType, required VoidCallback onConfirm}) {
    return showDialog(
      context: context,
      builder: (ctx) => ProtocolSwitchDialog(
        selectedBodyType: selectedBodyType,
        onConfirm: () {
          Navigator.of(ctx).pop();
          onConfirm();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('SWITCH TRAINING PROTOCOL?', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      content: Text(
        'Switching to ${selectedBodyType.toUpperCase()} protocol will calibrate your 90-day workout calendar to the new targeted split. Your past workout history, PRs, and streaks remain 100% saved!',
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('CANCEL', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('CONFIRM SWITCH'),
        ),
      ],
    );
  }
}
