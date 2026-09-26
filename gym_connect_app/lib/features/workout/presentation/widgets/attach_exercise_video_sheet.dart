import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/domain/models/user_role.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/youtube_video_utils.dart';
import '../../domain/models/workout_models.dart';
import '../providers/exercise_catalog_provider.dart';
import '../providers/workout_notifier.dart';
import '../../data/musclewiki_service.dart';
import 'fullscreen_video_dialog.dart';
import 'musclewiki_video_picker_dialog.dart';

class AttachExerciseVideoSheet extends ConsumerStatefulWidget {
  final Exercise exercise;

  const AttachExerciseVideoSheet({super.key, required this.exercise});

  static Future<bool?> show(BuildContext context, Exercise exercise) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachExerciseVideoSheet(exercise: exercise),
    );
  }

  @override
  ConsumerState<AttachExerciseVideoSheet> createState() =>
      _AttachExerciseVideoSheetState();
}

class _AttachExerciseVideoSheetState
    extends ConsumerState<AttachExerciseVideoSheet> {
  late final TextEditingController _videoUrlCtrl;
  late final TextEditingController _sideVideoUrlCtrl;
  bool _isSaving = false;
  bool _autoEmbedYouTube = true;

  @override
  void initState() {
    super.initState();
    _videoUrlCtrl =
        TextEditingController(text: widget.exercise.videoUrl ?? '');
    _videoUrlCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _sideVideoUrlCtrl =
        TextEditingController(text: widget.exercise.sideVideoUrl ?? '');
    _sideVideoUrlCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _videoUrlCtrl.dispose();
    _sideVideoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _openMuscleWikiPicker() async {
    final service = ref.read(muscleWikiServiceProvider);
    final selected = await MuscleWikiVideoPickerDialog.show(
      context,
      initialSearch: widget.exercise.name,
      initialMuscle: widget.exercise.targetMuscle,
      service: service,
    );
    if (selected != null) {
      setState(() {
        _videoUrlCtrl.text = selected.primaryVideoUrl;
        if (selected.sideVideoUrl != null && selected.sideVideoUrl!.isNotEmpty) {
          _sideVideoUrlCtrl.text = selected.sideVideoUrl!;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected MuscleWiki video: "${selected.title}" (${selected.quality})'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _previewVideo() {
    final rawUrl = _videoUrlCtrl.text.trim();
    if (rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a video URL first to preview.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final effectiveUrl =
        (_autoEmbedYouTube && YoutubeVideoUtils.isYouTubeUrl(rawUrl))
            ? YoutubeVideoUtils.toEmbedUrl(rawUrl,
                autoPlay: true, loop: true, mute: true)
            : rawUrl;

    final sideRaw = _sideVideoUrlCtrl.text.trim();
    final effectiveSideUrl = sideRaw.isNotEmpty
        ? ((_autoEmbedYouTube && YoutubeVideoUtils.isYouTubeUrl(sideRaw))
            ? YoutubeVideoUtils.toEmbedUrl(sideRaw,
                autoPlay: true, loop: true, mute: true)
            : sideRaw)
        : null;

    final tempExercise = widget.exercise.copyWith(
      videoUrl: effectiveUrl,
      sideVideoUrl: effectiveSideUrl,
    );
    FullscreenVideoDialog.show(context, tempExercise);
  }

  Future<void> _handleSave() async {
    final authState = ref.read(authNotifierProvider);
    final isAuthorized = (authState is AuthAuthenticated) &&
        (authState.activeRole == UserRole.superAdmin ||
            authState.activeRole == UserRole.owner);
    if (!isAuthorized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Only Super Admin and Gym Owner can edit workout videos.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final rawUrl = _videoUrlCtrl.text.trim();
    if (rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least a primary video URL.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final effectiveUrl =
        (_autoEmbedYouTube && YoutubeVideoUtils.isYouTubeUrl(rawUrl))
            ? YoutubeVideoUtils.toEmbedUrl(rawUrl,
                autoPlay: true, loop: true, mute: true)
            : rawUrl;

    final sideRaw = _sideVideoUrlCtrl.text.trim();
    final effectiveSideUrl = sideRaw.isNotEmpty
        ? ((_autoEmbedYouTube && YoutubeVideoUtils.isYouTubeUrl(sideRaw))
            ? YoutubeVideoUtils.toEmbedUrl(sideRaw,
                autoPlay: true, loop: true, mute: true)
            : sideRaw)
        : null;

    final success = await ref
        .read(exerciseCatalogNotifierProvider.notifier)
        .attachOrUpdateVideo(
          exerciseId: widget.exercise.id,
          videoUrl: effectiveUrl,
          sideVideoUrl: effectiveSideUrl,
          exerciseName: widget.exercise.name,
        );

    // Also update active workout session in phone if currently active
    ref.read(workoutNotifierProvider.notifier).loadTodayRoutine();

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Video attached to "${widget.exercise.name}" successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.video_camera_back_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ATTACH EXERCISE VIDEO',
                      style: GoogleFonts.oswald(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.exercise.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white60),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Primary Video Stream URL (Front Angle / Main)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _videoUrlCtrl,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'https://cdn.example.com/videos/squat_form.mp4 or YouTube link',
              hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
              prefixIcon: Icon(Icons.link_rounded, color: AppColors.primary, size: 20),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.fitness_center_rounded,
                        color: AppColors.primary),
                    tooltip: 'Search MuscleWiki API (1,900+ Videos)',
                    onPressed: _openMuscleWikiPicker,
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white70),
                    tooltip: 'Preview Stream',
                    onPressed: _previewVideo,
                  ),
                ],
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          if (YoutubeVideoUtils.isYouTubeUrl(_videoUrlCtrl.text.trim()))
            _buildYouTubeDetectedCard(_videoUrlCtrl.text.trim()),
          const SizedBox(height: 12),
          Text(
            'Side / Alternate Angle Video URL (Optional)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _sideVideoUrlCtrl,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'https://cdn.example.com/videos/squat_side.mp4 or YouTube link',
              hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
              prefixIcon: const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 20),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          if (YoutubeVideoUtils.isYouTubeUrl(_sideVideoUrlCtrl.text.trim()))
            _buildYouTubeDetectedCard(_sideVideoUrlCtrl.text.trim()),
          const SizedBox(height: 14),
          // Prominent MuscleWiki Search Action
          ElevatedButton.icon(
            onPressed: _openMuscleWikiPicker,
            icon: const Icon(Icons.fitness_center_rounded, size: 16),
            label: const Text('SEARCH MUSCLEWIKI (1,900+ HD FORM VIDEOS)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _previewVideo,
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('Preview Video'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(_isSaving ? 'SAVING...' : 'SAVE VIDEO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeDetectedCard(String url) {
    if (!YoutubeVideoUtils.isYouTubeUrl(url)) return const SizedBox.shrink();
    final videoId = YoutubeVideoUtils.extractVideoId(url);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.smart_display_rounded,
                    color: Colors.redAccent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'YOUTUBE DETECTED',
                          style: GoogleFonts.oswald(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'SAFE EMBED',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Official IFrame embedding with Autoplay & Loop. No copyright claims.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _autoEmbedYouTube,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                onChanged: (val) {
                  setState(() => _autoEmbedYouTube = val);
                },
              ),
            ],
          ),
          if (videoId != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Icon(Icons.tag_rounded,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Video ID: $videoId • Target: youtube-nocookie.com/embed (autoplay=1, mute=1, loop=1)',
                      style: GoogleFonts.robotoMono(
                          fontSize: 10, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
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
}
