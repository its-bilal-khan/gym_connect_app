import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/shared/widgets/action_card.dart';
import 'package:gym_connect_app/shared/widgets/primary_button.dart';
import 'package:gym_connect_app/features/staff/data/staff_reception_repository.dart';
import 'package:gym_connect_app/features/staff/presentation/widgets/staff_check_in_dialog.dart';
import 'package:gym_connect_app/features/staff/presentation/widgets/staff_walk_in_dialog.dart';

class StaffReceptionTab extends ConsumerWidget {
  const StaffReceptionTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'RECEPTION CHECK-IN DESK',
              style: GoogleFonts.oswald(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              text: 'SCAN MEMBER QR CODE',
              icon: Icons.qr_code_scanner_rounded,
              onPressed: () => StaffCheckInDialog.show(context),
            ),
            const SizedBox(height: 14),
            ActionCard(
              icon: Icons.lock_open_rounded,
              title: 'Emergency Gate Unlock',
              subtitle: 'Trigger ESP32 Wi-Fi relay manual pulse (10s)',
              actionLabel: 'PULSE GATE',
              onTap: () async {
                final success = await ref.read(staffReceptionRepositoryProvider).pulseEmergencyGate();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? '⚡ ESP32 Gate Relay Pulsed (10s unlock)' : 'Gate pulse command failed',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.background),
                      ),
                      backgroundColor: success ? AppColors.primaryAccent : Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            ActionCard(
              icon: Icons.person_add_rounded,
              title: 'Walk-In Registration',
              subtitle: 'Enroll a new walk-in guest or member (24h pass)',
              actionLabel: 'REGISTER',
              onTap: () => StaffWalkInDialog.show(context),
            ),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
