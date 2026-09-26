import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../workout/data/youtube_video_utils.dart';
import '../../../../workout/domain/models/workout_models.dart';
import '../../../../workout/presentation/providers/exercise_catalog_provider.dart';
import '../../../../workout/presentation/providers/workout_notifier.dart';
import '../../../../workout/data/musclewiki_service.dart';
import '../../../../workout/presentation/widgets/fullscreen_video_dialog.dart';
import '../../../../workout/presentation/widgets/musclewiki_video_picker_dialog.dart';

class AddEditExerciseVideoDialog extends ConsumerStatefulWidget {
  final Exercise? initialExercise;

  const AddEditExerciseVideoDialog({super.key, this.initialExercise});

  static Future<Exercise?> show(BuildContext context, {Exercise? exercise}) {
    return showDialog<Exercise>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditExerciseVideoDialog(initialExercise: exercise),
    );
  }

  @override
  ConsumerState<AddEditExerciseVideoDialog> createState() =>
      _AddEditExerciseVideoDialogState();
}

class _AddEditExerciseVideoDialogState
    extends ConsumerState<AddEditExerciseVideoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _videoUrlCtrl;
  late final TextEditingController _sideVideoUrlCtrl;
  late final TextEditingController _thumbnailUrlCtrl;
  late final TextEditingController _tipsCtrl;

  late String _targetMuscle;
  late String _equipment;
  late String _difficulty;
  bool _isSaving = false;
  bool _autoEmbedYouTube = true;

  static const _muscles = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Full Body',
  ];

  static const _equipments = [
    'Barbell',
    'Dumbbell',
    'Machine',
    'Cable',
    'Bodyweight',
    'Kettlebell',
    'Resistance Band',
  ];

  static const _difficulties = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    final ex = widget.initialExercise;
    _nameCtrl = TextEditingController(text: ex?.name ?? '');
    _videoUrlCtrl = TextEditingController(text: ex?.videoUrl ?? '');
    _videoUrlCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _sideVideoUrlCtrl = TextEditingController(text: ex?.sideVideoUrl ?? '');
    _sideVideoUrlCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _thumbnailUrlCtrl = TextEditingController(text: ex?.thumbnailUrl ?? '');
    _thumbnailUrlCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _tipsCtrl = TextEditingController(
        text: ex?.tips ?? 'Maintain core tension and controlled eccentric tempo.');

    _targetMuscle = _muscles.contains(ex?.targetMuscle)
        ? ex!.targetMuscle
        : _muscles.first;
    _equipment = _equipments.contains(ex?.equipment)
        ? ex!.equipment
        : _equipments.first;
    _difficulty = _difficulties.contains(ex?.difficulty)
        ? ex!.difficulty
        : _difficulties[1];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _videoUrlCtrl.dispose();
    _sideVideoUrlCtrl.dispose();
    _thumbnailUrlCtrl.dispose();
    _tipsCtrl.dispose();
    super.dispose();
  }

  Future<void> _openMuscleWikiPicker() async {
    final service = ref.read(muscleWikiServiceProvider);
    final selected = await MuscleWikiVideoPickerDialog.show(
      context,
      initialSearch: _nameCtrl.text.trim(),
      initialMuscle: _targetMuscle,
      service: service,
    );
    if (selected != null) {
      setState(() {
        _videoUrlCtrl.text = selected.primaryVideoUrl;
        if (selected.sideVideoUrl != null && selected.sideVideoUrl!.isNotEmpty) {
          _sideVideoUrlCtrl.text = selected.sideVideoUrl!;
        }
        if (_nameCtrl.text.trim().isEmpty) {
          _nameCtrl.text = selected.title;
        }
        if (_muscles.contains(selected.targetMuscle)) {
          _targetMuscle = selected.targetMuscle;
        }
        if (_equipments.contains(selected.equipment)) {
          _equipment = selected.equipment;
        }
        if (_tipsCtrl.text.trim().isEmpty ||
            _tipsCtrl.text == 'Maintain core tension and controlled eccentric tempo.') {
          _tipsCtrl.text = selected.tips;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied MuscleWiki Video: "${selected.title}" (${selected.quality})'),
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

    final tempExercise = Exercise(
      id: widget.initialExercise?.id ?? 'temp-preview',
      name: _nameCtrl.text.trim().isEmpty
          ? 'Exercise Preview'
          : _nameCtrl.text.trim(),
      targetMuscle: _targetMuscle,
      equipment: _equipment,
      difficulty: _difficulty,
      videoUrl: effectiveUrl,
      sideVideoUrl: effectiveSideUrl,
      tips: _tipsCtrl.text.trim(),
    );
    FullscreenVideoDialog.show(context, tempExercise);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final id = widget.initialExercise?.id ??
        'ex-${DateTime.now().millisecondsSinceEpoch}';

    String? primaryVideo = _videoUrlCtrl.text.trim().isNotEmpty
        ? _videoUrlCtrl.text.trim()
        : null;
    if (primaryVideo != null &&
        _autoEmbedYouTube &&
        YoutubeVideoUtils.isYouTubeUrl(primaryVideo)) {
      primaryVideo = YoutubeVideoUtils.toEmbedUrl(primaryVideo,
          autoPlay: true, loop: true, mute: true);
    }

    String? sideVideo = _sideVideoUrlCtrl.text.trim().isNotEmpty
        ? _sideVideoUrlCtrl.text.trim()
        : null;
    if (sideVideo != null &&
        _autoEmbedYouTube &&
        YoutubeVideoUtils.isYouTubeUrl(sideVideo)) {
      sideVideo = YoutubeVideoUtils.toEmbedUrl(sideVideo,
          autoPlay: true, loop: true, mute: true);
    }

    String? thumbUrl = _thumbnailUrlCtrl.text.trim().isNotEmpty
        ? _thumbnailUrlCtrl.text.trim()
        : null;

    final exercise = Exercise(
      id: id,
      name: _nameCtrl.text.trim(),
      targetMuscle: _targetMuscle,
      equipment: _equipment,
      difficulty: _difficulty,
      videoUrl: primaryVideo,
      sideVideoUrl: sideVideo,
      thumbnailUrl: thumbUrl,
      tips: _tipsCtrl.text.trim(),
      instructions: widget.initialExercise?.instructions ?? const [],
    );

    final success = await ref
        .read(exerciseCatalogNotifierProvider.notifier)
        .addOrUpdateExercise(exercise, isGlobal: true);

    try {
      ref.read(workoutNotifierProvider.notifier).loadTodayRoutine();
    } catch (_) {}

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop(exercise);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Exercise "${exercise.name}" updated with video.'
                : 'Exercise "${exercise.name}" updated for this session.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _previewThumbnail() {
    final url = _thumbnailUrlCtrl.text.trim();
    if (url.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'THUMBNAIL PREVIEW',
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  width: 320,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 320,
                    height: 200,
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.error,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: GoogleFonts.inter(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialExercise != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isEdit),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _nameCtrl,
                          label: 'Exercise Name',
                          hint: 'e.g. Incline Dumbbell Bench Press',
                          icon: Icons.fitness_center_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter exercise name'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                label: 'Target Muscle',
                                value: _targetMuscle,
                                items: _muscles,
                                icon: Icons.accessibility_new_rounded,
                                onChanged: (v) =>
                                    setState(() => _targetMuscle = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                label: 'Equipment',
                                value: _equipment,
                                items: _equipments,
                                icon: Icons.sports_gymnastics_rounded,
                                onChanged: (v) =>
                                    setState(() => _equipment = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                label: 'Difficulty',
                                value: _difficulty,
                                items: _difficulties,
                                icon: Icons.speed_rounded,
                                onChanged: (v) =>
                                    setState(() => _difficulty = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildVideoSectionHeader(),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _videoUrlCtrl,
                          label: 'Front Angle Video Stream (Main)',
                          hint: 'Direct MP4/WebM URL or YouTube link',
                          icon: Icons.video_camera_front_rounded,
                          suffixIcon: _videoUrlCtrl.text.trim().isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.play_circle_fill_rounded,
                                      color: AppColors.primary),
                                  tooltip: 'Preview Stream',
                                  onPressed: _previewVideo,
                                )
                              : null,
                        ),
                        if (YoutubeVideoUtils.isYouTubeUrl(_videoUrlCtrl.text.trim()))
                          _buildYouTubeDetectedCard(_videoUrlCtrl.text.trim()),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _sideVideoUrlCtrl,
                          label: 'Side Angle Video Stream (Optional)',
                          hint: 'Alternate angle URL for dual-view synchronization',
                          icon: Icons.camera_alt_outlined,
                          suffixIcon: _sideVideoUrlCtrl.text.trim().isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.play_circle_fill_rounded,
                                      color: AppColors.primary),
                                  tooltip: 'Preview Dual Angle',
                                  onPressed: _previewVideo,
                                )
                              : null,
                        ),
                        if (YoutubeVideoUtils.isYouTubeUrl(_sideVideoUrlCtrl.text.trim()))
                          _buildYouTubeDetectedCard(_sideVideoUrlCtrl.text.trim()),
                        const SizedBox(height: 18),
                        _buildSectionHeader('COACHING & PREVIEW', icon: Icons.tune_rounded),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _thumbnailUrlCtrl,
                          label: 'Thumbnail Image URL (Optional)',
                          hint: 'https://cdn.example.com/images/exercise.jpg',
                          icon: Icons.image_rounded,
                          suffixIcon: _thumbnailUrlCtrl.text.trim().isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.visibility_rounded,
                                      color: AppColors.primary),
                                  tooltip: 'Preview Thumbnail',
                                  onPressed: _previewThumbnail,
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _tipsCtrl,
                          label: 'Form Cues & Execution Notes',
                          hint: 'Key biomechanical cues (e.g. Retract scapula, control descent)',
                          icon: Icons.lightbulb_outline_rounded,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildActionButtons(isEdit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEdit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.video_library_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'EDIT EXERCISE & VIDEO' : 'ADD NEW EXERCISE',
                      style: GoogleFonts.oswald(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Configure exercise streams, dual angles, and coaching cues',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white60),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildVideoSectionHeader() {
    return Row(
      children: [
        Icon(Icons.videocam_rounded, color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Text(
          'VIDEO STREAMS',
          style: GoogleFonts.oswald(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_rounded, size: 13, color: Colors.white70),
              const SizedBox(width: 5),
              Text(
                'CUSTOM VIDEO URL',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Search 1,900+ exercise video demonstrations',
          child: InkWell(
            onTap: _openMuscleWikiPicker,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fitness_center_rounded,
                      size: 13, color: Colors.black),
                  const SizedBox(width: 6),
                  Text(
                    'MUSCLEWIKI ⚡',
                    style: GoogleFonts.oswald(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: GoogleFonts.oswald(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: AppColors.surface,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildYouTubeDetectedCard(String url) {
    if (!YoutubeVideoUtils.isYouTubeUrl(url)) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.smart_display_rounded,
                color: Colors.redAccent, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'YOUTUBE DETECTED',
                  style: GoogleFonts.oswald(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'COPYRIGHT-SAFE EMBED',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Auto-Embed\n& Loop',
                textAlign: TextAlign.end,
                style: GoogleFonts.oswald(
                  fontSize: 10,
                  color: _autoEmbedYouTube ? AppColors.primary : Colors.white54,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: _autoEmbedYouTube,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                  onChanged: (val) => setState(() => _autoEmbedYouTube = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isEdit) {
    final hasVideo = _videoUrlCtrl.text.trim().isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          onPressed: hasVideo ? _previewVideo : null,
          icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
          label: const Text('Test Video Stream'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white24,
            side: BorderSide(
              color: hasVideo ? AppColors.border : AppColors.border.withValues(alpha: 0.4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 16),
              label: Text(_isSaving
                  ? 'SAVING...'
                  : (isEdit ? 'UPDATE EXERCISE' : 'SAVE EXERCISE')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
