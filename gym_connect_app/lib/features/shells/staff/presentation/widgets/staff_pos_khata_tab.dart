import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/shared/widgets/action_card.dart';
import 'package:gym_connect_app/features/staff/presentation/widgets/staff_pos_register_sheet.dart';

class StaffPosKhataTab extends StatelessWidget {
  const StaffPosKhataTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'POS & KHATA CREDIT SYSTEM',
              style: GoogleFonts.oswald(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ActionCard(
              icon: Icons.point_of_sale_rounded,
              title: 'New POS Sale',
              subtitle: 'Supplements, drinks, gear (Cash, Card, JazzCash, Khata Credit)',
              actionLabel: 'OPEN REGISTER',
              onTap: () => StaffPosRegisterSheet.show(context),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: AppColors.primaryAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'RETAIL CAPABILITIES',
                        style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.inventory_2_rounded, 'Real-time Supabase stock deduction'),
                  const SizedBox(height: 8),
                  _buildFeatureRow(Icons.payments_rounded, 'Split payment support (Cash + Online)'),
                  const SizedBox(height: 8),
                  _buildFeatureRow(Icons.book_rounded, 'Khata Credit book ledger for verified members'),
                  const SizedBox(height: 8),
                  _buildFeatureRow(Icons.print_rounded, '80mm / 58mm thermal receipt generation'),
                ],
              ),
            ),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
