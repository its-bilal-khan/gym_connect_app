import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/user_profile.dart';
import 'widgets/gate_pass_card.dart';
import 'widgets/member_profile_tab.dart';
import 'widgets/member_today_tab.dart';
import 'widgets/member_workout_hub_tab.dart';

class MemberShellView extends ConsumerWidget {
  final UserProfile profile;
  final int selectedIndex;

  const MemberShellView({
    super.key,
    required this.profile,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (selectedIndex) {
      case 0:
        return const MemberTodayTab();
      case 1:
        return const MemberWorkoutHubTab();
      case 2:
        return _buildGatePassTab(context);
      case 3:
      default:
        return const MemberProfileTab();
    }
  }

  Widget _buildGatePassTab(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const GatePassCard(),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
