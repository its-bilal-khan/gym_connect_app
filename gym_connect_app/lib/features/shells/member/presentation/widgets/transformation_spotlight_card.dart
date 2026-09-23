import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../community/data/community_repository.dart';

class TransformationSpotlightCard extends ConsumerStatefulWidget {
  const TransformationSpotlightCard({super.key});

  @override
  ConsumerState<TransformationSpotlightCard> createState() => _TransformationSpotlightCardState();
}

class _TransformationSpotlightCardState extends ConsumerState<TransformationSpotlightCard> {
  int? _localLikes;
  bool _isLiked = false;

  void _toggleLike(TransformationPost post) {
    HapticFeedback.lightImpact();
    final current = _localLikes ?? post.likesCount;
    setState(() {
      _isLiked = !_isLiked;
      _localLikes = current + (_isLiked ? 1 : -1);
    });
    ref.read(communityRepositoryProvider).updateLikes(post.id, _localLikes!);
  }

  void _showStoryDialog(BuildContext context, TransformationPost post) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          post.title,
          style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('WEIGHT', post.weightLoss),
                  _statItem('BODY FAT', post.bodyFat),
                  _statItem('PROGRAM', post.program),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '"${post.story}"',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('CLOSE', style: GoogleFonts.oswald(color: AppColors.primaryAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final postAsync = ref.watch(transformationSpotlightProvider);

    final post = postAsync.asData?.value ??
        const TransformationPost(
          id: '00000000-0000-0000-0000-000000000041',
          title: "Ahmad's 90-Day Shred Story",
          story: "GymConnect ke 90-day smart calendar aur calorie engine ne meri life badal di! Har roz ka routine auto-load hota tha aur sets log karte hue rest timer ne discipline banaye rakha.",
          memberName: "Ahmad Raza",
          weightLoss: "-14.5 KG",
          bodyFat: "28% ➔ 15%",
          program: "SHRED D-90",
          daysActive: 78,
          likesCount: 143,
        );

    final currentLikes = _localLikes ?? post.likesCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      'AI COACH TIP',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                  ],
                ),
              ),
              Text(
                'COMMUNITY',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Eccentric Cadence for Hypertrophy',
            style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Lower weights with a 3-second negative. Controlled tempo produces 35% higher muscle activation than rushing reps.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: AppColors.primaryAccent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${post.memberName}'s 90-Day Transformation",
                      style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Down ${post.weightLoss.replaceAll('-', '')} • ${post.program} • Day ${post.daysActive}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _toggleLike(post),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isLiked ? Colors.redAccent : AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$currentLikes',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _isLiked ? Colors.redAccent : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _showStoryDialog(context, post),
              child: Text(
                'READ STORY & PROTOCOL →',
                style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
