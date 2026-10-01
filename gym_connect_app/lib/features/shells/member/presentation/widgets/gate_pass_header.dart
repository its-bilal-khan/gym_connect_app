import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../gamification/presentation/providers/device_lock_provider.dart';

class GatePassHeader extends ConsumerWidget {
  final int secondsRemaining;
  final Color accent;

  const GatePassHeader({
    super.key,
    required this.secondsRemaining,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(deviceLockProvider);
    final isMismatch = lockState.isMismatch;

    final badgeColor = isMismatch ? Colors.redAccent : Colors.greenAccent;
    final badgeText = isMismatch ? 'UNAUTHORIZED DEVICE' : 'DEVICE ID LOCKED';
    final icon = isMismatch ? Icons.gpp_bad_rounded : Icons.verified_user_rounded;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: badgeColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: badgeColor, size: 14),
              const SizedBox(width: 4),
              Text(
                badgeText,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: secondsRemaining / 10.0,
                strokeWidth: 2.5,
                color: accent,
                backgroundColor: Colors.white10,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${secondsRemaining}s',
              style: GoogleFonts.oswald(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
