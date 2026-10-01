import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../calculators/presentation/screens/calculators_hub_screen.dart';
import 'widgets/owner_overview_tab.dart';
import 'widgets/owner_settings_tab.dart';
import 'widgets/owner_staff_audit_tab.dart';
import 'widgets/owner_operations_tab.dart';

class OwnerShellView extends StatelessWidget {
  final UserProfile profile;
  final int selectedIndex;

  const OwnerShellView({
    super.key,
    required this.profile,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (selectedIndex) {
      case 0:
        content = OwnerOverviewTab(profile: profile);
        break;
      case 1:
        content = OwnerStaffAuditTab(profile: profile);
        break;
      case 2:
        content = OwnerOperationsTab(profile: profile);
        break;
      case 3:
        content = const CalculatorsHubScreen();
        break;
      case 4:
      default:
        content = OwnerSettingsTab(profile: profile);
        break;
    }

    try {
      ProviderScope.containerOf(context, listen: false);
      return content;
    } catch (_) {
      return ProviderScope(child: content);
    }
  }
}

