import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class StoreFulfillmentCard extends StatelessWidget {
  final bool isDelivery;
  final ValueChanged<bool> onToggleFulfillment;
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;

  const StoreFulfillmentCard({
    super.key,
    required this.isDelivery,
    required this.onToggleFulfillment,
    required this.nameController,
    required this.addressController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOW DO YOU WANT TO RECEIVE YOUR ORDER?', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildChoiceButton(
                  title: 'IN-GYM PICKUP',
                  subtitle: 'Free • Ready at Reception',
                  icon: Icons.storefront_rounded,
                  isSelected: !isDelivery,
                  onTap: () => onToggleFulfillment(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildChoiceButton(
                  title: 'HOME DELIVERY',
                  subtitle: 'Rider to Your Doorstep',
                  icon: Icons.delivery_dining_rounded,
                  isSelected: isDelivery,
                  onTap: () => onToggleFulfillment(true),
                ),
              ),
            ],
          ),
          if (isDelivery) ...[
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              decoration: _inputDecoration('Recipient Full Name', Icons.person_outline_rounded),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              maxLines: 2,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              decoration: _inputDecoration('Delivery Address (Street, House/Flat, City)', Icons.home_outlined),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              decoration: _inputDecoration('Contact Phone Number for Courier', Icons.phone_outlined),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Collect at gym front desk counter. A pickup code & barcode will be generated upon checkout.',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChoiceButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.5 : 1.0),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
            const SizedBox(height: 6),
            Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
      prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
