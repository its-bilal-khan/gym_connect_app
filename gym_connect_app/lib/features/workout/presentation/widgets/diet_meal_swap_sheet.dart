import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class DietMealSwapSheet extends StatefulWidget {
  final String originalItem;
  final String category;

  const DietMealSwapSheet({
    super.key,
    this.originalItem = 'Rolled Oats (100g)',
    this.category = 'Clean Carbs',
  });

  static Future<void> show(
    BuildContext context, {
    String originalItem = 'Rolled Oats (100g)',
    String category = 'Clean Carbs',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DietMealSwapSheet(originalItem: originalItem, category: category),
    );
  }

  @override
  State<DietMealSwapSheet> createState() => _DietMealSwapSheetState();
}

class _DietMealSwapSheetState extends State<DietMealSwapSheet> {
  final List<Map<String, String>> _alternatives = [
    {'name': 'Sweet Potato (250g)', 'macros': '350 kcal • 4g Protein • 80g Carbs', 'badge': 'Equiv Carbs'},
    {'name': 'Brown Basmati Rice (180g)', 'macros': '360 kcal • 7g Protein • 76g Carbs', 'badge': 'Clean Grain'},
    {'name': 'Quinoa Bowl (200g)', 'macros': '370 kcal • 14g Protein • 68g Carbs', 'badge': 'High Protein Grain'},
    {'name': 'Whole Wheat Toast & Banana', 'macros': '340 kcal • 8g Protein • 72g Carbs', 'badge': 'Quick Digest'},
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.70,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1-TAP DIET & MEAL SWAP', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('Substitute "${widget.originalItem}" (${widget.category})', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text('0 PT PENALTY', style: GoogleFonts.oswald(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: _alternatives.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final alt = _alternatives[idx];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.restaurant_rounded, color: accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(alt['name']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              Text(alt['macros']!, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Meal Swapped to "${alt['name']}" (0 Pt Penalty Applied)!'),
                              backgroundColor: AppColors.surface,
                            ));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          child: Text('SWAP', style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
