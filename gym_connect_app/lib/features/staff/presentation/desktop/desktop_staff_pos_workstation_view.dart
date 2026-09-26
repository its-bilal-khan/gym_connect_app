import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/services/secure_storage_service.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/shells/staff/presentation/widgets/staff_members_directory_tab.dart';
import 'package:gym_connect_app/features/shells/staff/presentation/widgets/staff_reception_tab.dart';
import 'package:gym_connect_app/features/shells/staff/presentation/widgets/staff_shift_tally_tab.dart';
import 'widgets/desktop_pos_register_screen.dart';

class DesktopStaffPosWorkstationView extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const DesktopStaffPosWorkstationView({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<DesktopStaffPosWorkstationView> createState() =>
      _DesktopStaffPosWorkstationViewState();
}

class _DesktopStaffPosWorkstationViewState
    extends ConsumerState<DesktopStaffPosWorkstationView> {
  late int _activeSubTab;

  @override
  void initState() {
    super.initState();
    _activeSubTab = widget.initialTabIndex;
    _restoreSavedTab();
  }

  Future<void> _restoreSavedTab() async {
    final storage = ref.read(secureStorageProvider);
    final saved = await storage.getActiveSubTab('staff_pos');
    if (saved != null && mounted) {
      if (saved >= 0 && saved < _subTabs.length) {
        setState(() => _activeSubTab = saved);
      }
    }
  }

  void _onTabSelected(int index) {
    setState(() => _activeSubTab = index);
    ref.read(secureStorageProvider).saveActiveSubTab('staff_pos', index);
    ref.read(secureStorageProvider).saveActiveNavIndex(index);
  }

  @override
  void didUpdateWidget(covariant DesktopStaffPosWorkstationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _activeSubTab = widget.initialTabIndex;
      ref
          .read(secureStorageProvider)
          .saveActiveSubTab('staff_pos', widget.initialTabIndex);
    }
  }

  static const _subTabs = [
    (title: 'POS REGISTER DESK', icon: Icons.point_of_sale_rounded),
    (title: 'GATE CHECK-INS & TURNSTILE', icon: Icons.door_sliding_rounded),
    (title: 'MEMBERS DIRECTORY & PASSES', icon: Icons.people_alt_rounded),
    (title: 'SHIFT TALLY & Z-REPORT', icon: Icons.receipt_long_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWorkstationHeader(),
        Expanded(
          child: switch (_activeSubTab) {
            0 => const DesktopPosRegisterScreen(),
            1 => const StaffReceptionTab(),
            2 => const StaffMembersDirectoryTab(),
            3 => const StaffShiftTallyTab(),
            _ => const DesktopPosRegisterScreen(),
          },
        ),
      ],
    );
  }

  Widget _buildWorkstationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Icon(Icons.desktop_windows_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'DESKTOP POS WORKSTATION',
                style: GoogleFonts.oswald(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_subTabs.length, (i) {
                  final t = _subTabs[i];
                  final isSelected = _activeSubTab == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _onTabSelected(i),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon,
                                size: 14,
                                color:
                                    isSelected ? Colors.black : Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              t.title,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
