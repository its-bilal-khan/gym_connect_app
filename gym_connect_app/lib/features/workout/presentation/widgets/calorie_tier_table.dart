import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/services/bmi_calorie_engine.dart';

class CalorieTierTable extends StatefulWidget {
  final List<CalorieTier> lossTiers;
  final List<CalorieTier> gainTiers;
  final int selectedCalories;
  final ValueChanged<CalorieTier> onSelectTier;

  const CalorieTierTable({
    super.key,
    required this.lossTiers,
    required this.gainTiers,
    required this.selectedCalories,
    required this.onSelectTier,
  });

  @override
  State<CalorieTierTable> createState() => _CalorieTierTableState();
}

class _CalorieTierTableState extends State<CalorieTierTable> {
  bool _showGain = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final tiers = _showGain ? widget.gainTiers : widget.lossTiers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TARGET CALORIE TIERS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            Row(
              children: [
                _tabBtn('DEFICIT / LOSS', !_showGain, accent, () => setState(() => _showGain = false)),
                const SizedBox(width: 6),
                _tabBtn('SURPLUS / GAIN', _showGain, accent, () => setState(() => _showGain = true)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...tiers.map((tier) => _tierRow(tier, accent)),
      ],
    );
  }

  Widget _tabBtn(String label, bool isSel, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSel ? accent.withValues(alpha: 0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSel ? accent : AppColors.border),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: isSel ? accent : AppColors.textSecondary)),
      ),
    );
  }

  Widget _tierRow(CalorieTier tier, Color accent) {
    final isSelected = widget.selectedCalories == tier.calories;
    final formattedCal = _formatNumber(tier.calories);

    return GestureDetector(
      onTap: () => widget.onSelectTier(tier),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? accent : AppColors.border, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tier.title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text(tier.pace, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const Icon(Icons.arrow_right_rounded, color: AppColors.textSecondary, size: 20),
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? accent.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.03),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formattedCal, style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? accent : AppColors.textPrimary)),
                        Text('Calories/day', style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? accent.withValues(alpha: 0.25) : Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('${tier.percentage}%', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? accent : AppColors.textPrimary)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int num) {
    final s = num.toString();
    if (s.length > 3) {
      return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return s;
  }
}
