import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../reviews/data/reviews_repository.dart';

class GymReviewDialog extends ConsumerStatefulWidget {
  const GymReviewDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => const GymReviewDialog(),
    );
  }

  @override
  ConsumerState<GymReviewDialog> createState() => _GymReviewDialogState();
}

class _GymReviewDialogState extends ConsumerState<GymReviewDialog> {
  int _rating = 5;
  final TextEditingController _reviewController = TextEditingController();
  final Set<String> _selectedTags = {'Cleanliness', 'Equipments'};
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  final List<String> _tags = ['Cleanliness', 'Equipments', 'Trainers', 'Crowd Levels', 'AC & Ventilation'];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);
    final title = _selectedTags.isNotEmpty ? _selectedTags.join(' • ') : 'Member Workout Feedback';
    await ref.read(reviewsRepositoryProvider).submitGymReview(
      rating: _rating,
      reviewTitle: title,
      reviewText: _reviewController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('RATE YOUR GYM', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Colors.cyanAccent, size: 16),
                  const SizedBox(width: 6),
                  Text('VERIFIED ACTIVE MEMBER', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                ],
              ),
              const SizedBox(height: 16),
              if (_isSubmitted) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.amber, size: 44),
                      const SizedBox(height: 8),
                      Text('REVIEW SUBMITTED!', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Your verified member review was successfully synced to the gym database.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('CLOSE', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      icon: Icon(star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 36),
                      onPressed: () => setState(() => _rating = star),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text('WHAT STOOD OUT?', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _tags.map((tag) {
                    final selected = _selectedTags.contains(tag);
                    return ChoiceChip(
                      label: Text(tag, style: GoogleFonts.inter(fontSize: 11, color: selected ? Colors.black : AppColors.textPrimary)),
                      selected: selected,
                      selectedColor: accent,
                      backgroundColor: AppColors.background,
                      onSelected: (val) {
                        setState(() {
                          val ? _selectedTags.add(tag) : _selectedTags.remove(tag);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Share your workout experience...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text('SUBMIT VERIFIED REVIEW', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
