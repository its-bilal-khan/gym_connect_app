import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/action_card.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/domain/models/user_profile.dart';

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
        return _buildReceptionTab(context);
      case 1:
        return _buildMembersTab(context);
      case 2:
        return _buildPosKhataTab(context);
      case 3:
      default:
        return _buildShiftTallyTab(context);
    }
  }

  Widget _buildReceptionTab(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('RECEPTION CHECK-IN DESK', style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            PrimaryButton(text: 'SCAN MEMBER QR CODE', icon: Icons.qr_code_scanner_rounded, onPressed: () {}),
            const SizedBox(height: 14),
            const ActionCard(icon: Icons.lock_open_rounded, title: 'Emergency Gate Unlock', subtitle: 'Trigger ESP32 Wi-Fi relay manual pulse (10s)', actionLabel: 'PULSE GATE'),
            const SizedBox(height: 12),
            const ActionCard(icon: Icons.person_add_rounded, title: 'Walk-In Registration', subtitle: 'Enroll a new walk-in guest or member', actionLabel: 'REGISTER'),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MEMBER DIRECTORY & LOOKUP', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or membership ID...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            const ActionCard(icon: Icons.account_circle_rounded, title: 'Ali Hamza (ID: #4092)', subtitle: 'VIP Plan • Valid until Dec 2026 • Status: ACTIVE', actionLabel: 'PROFILE'),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildPosKhataTab(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('POS & KHATA CREDIT SYSTEM', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            const ActionCard(icon: Icons.point_of_sale_rounded, title: 'New POS Sale', subtitle: 'Supplements, drinks, gear (Cash, Card, JazzCash, Khata)', actionLabel: 'OPEN REGISTER'),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftTallyTab(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SHIFT TALLY & Z-REPORT', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            const ActionCard(icon: Icons.receipt_long_rounded, title: 'Current Shift Tally', subtitle: 'Cash Drawer: \$540.00 • 14 Invoices Collected', actionLabel: 'PRINT Z-REPORT'),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
