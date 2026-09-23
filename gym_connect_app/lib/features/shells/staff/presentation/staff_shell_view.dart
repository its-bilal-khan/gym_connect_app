import 'package:flutter/material.dart';
import '../../../auth/domain/models/user_profile.dart';
import 'widgets/staff_members_directory_tab.dart';
import 'widgets/staff_pos_khata_tab.dart';
import 'widgets/staff_reception_tab.dart';
import 'widgets/staff_shift_tally_tab.dart';

class StaffShellView extends StatelessWidget {
  final UserProfile profile;
  final int selectedIndex;

  const StaffShellView({
    super.key,
    required this.profile,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return const StaffReceptionTab();
      case 1:
        return const StaffMembersDirectoryTab();
      case 2:
        return const StaffPosKhataTab();
      case 3:
      default:
        return const StaffShiftTallyTab();
    }
  }
}
