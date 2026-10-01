import 'package:flutter/material.dart';
import '../../../gamification/presentation/widgets/dual_track_leaderboard_sheet.dart';

/// Legacy facade delegating to Phase 6 DualTrackLeaderboardSheet.
class GymLeaderboardSheet extends StatelessWidget {
  const GymLeaderboardSheet({super.key});

  static Future<void> show(BuildContext context) {
    return DualTrackLeaderboardSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return const DualTrackLeaderboardSheet();
  }
}

