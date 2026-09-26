import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/gym_member.dart';

class FreezeMembershipDialog extends StatefulWidget {
  final GymMember member;
  final Function(String? reason) onConfirm;

  const FreezeMembershipDialog({
    super.key,
    required this.member,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required GymMember member,
    required Function(String? reason) onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (_) => FreezeMembershipDialog(
        member: member,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<FreezeMembershipDialog> createState() => _FreezeMembershipDialogState();
}

class _FreezeMembershipDialogState extends State<FreezeMembershipDialog> {
  final TextEditingController _reasonCtrl = TextEditingController(text: 'Medical / Travel Leave');

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentlyFrozen = widget.member.isFrozen;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isCurrentlyFrozen ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.cyanAccent.withValues(alpha: 0.4)),
      ),
      title: Row(
        children: [
          Icon(
            isCurrentlyFrozen ? Icons.play_circle_outline_rounded : Icons.pause_circle_outline_rounded,
            color: isCurrentlyFrozen ? Colors.greenAccent : Colors.cyanAccent,
          ),
          const SizedBox(width: 10),
          Text(
            isCurrentlyFrozen ? 'UNFREEZE MEMBERSHIP' : 'FREEZE MEMBERSHIP',
            style: GoogleFonts.oswald(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCurrentlyFrozen
                  ? 'Are you sure you want to unfreeze ${widget.member.fullName}\'s membership? Turnstile gate access will be restored immediately.'
                  : 'Freezing temporarily pauses ${widget.member.fullName}\'s membership so their paid days are not lost during travel or medical leave.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (!isCurrentlyFrozen) ...[
              const SizedBox(height: 14),
              Text('REASON FOR FREEZE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonCtrl,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accent)),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isCurrentlyFrozen ? Colors.greenAccent : Colors.cyanAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            widget.onConfirm(isCurrentlyFrozen ? null : _reasonCtrl.text.trim());
            Navigator.of(context).pop();
          },
          child: Text(
            isCurrentlyFrozen ? 'Unfreeze Now' : 'Freeze Membership',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
