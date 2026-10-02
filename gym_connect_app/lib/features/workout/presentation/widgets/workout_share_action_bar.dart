import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkoutShareActionBar extends StatelessWidget {
  final VoidCallback onShareToCommunity;
  final VoidCallback onSaveToProfile;
  final VoidCallback onSkip;
  final bool isSharing;
  final bool isSaving;

  const WorkoutShareActionBar({
    super.key,
    required this.onShareToCommunity,
    required this.onSaveToProfile,
    required this.onSkip,
    this.isSharing = false,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: (isSharing || isSaving) ? null : onShareToCommunity,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
          child: isSharing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rocket_launch_rounded, size: 20, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      'SHARE TO COMMUNITY FEED',
                      style: GoogleFonts.oswald(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: (isSharing || isSaving) ? null : onSaveToProfile,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white24, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bookmark_add_rounded, size: 18, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(
                      'SAVE TO MY PROFILE',
                      style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: (isSharing || isSaving) ? null : onSkip,
          child: Text(
            'Skip & Return to Hub',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
