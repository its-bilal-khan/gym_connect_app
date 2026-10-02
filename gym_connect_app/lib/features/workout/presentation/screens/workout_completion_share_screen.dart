import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../gamification/data/explore_reels_repository.dart';
import '../../../gamification/presentation/providers/explore_reels_provider.dart';
import '../widgets/workout_share_action_bar.dart';
import '../widgets/workout_video_loop_card.dart';

class WorkoutCompletionShareScreen extends ConsumerStatefulWidget {
  final String? videoPath;
  final String? videoUrl;
  final String routineTitle;
  final int totalSets;
  final int totalReps;
  final int durationMinutes;

  const WorkoutCompletionShareScreen({
    super.key,
    this.videoPath,
    this.videoUrl,
    this.routineTitle = 'Workout Session',
    this.totalSets = 12,
    this.totalReps = 96,
    this.durationMinutes = 45,
  });

  @override
  ConsumerState<WorkoutCompletionShareScreen> createState() => _WorkoutCompletionShareScreenState();
}

class _WorkoutCompletionShareScreenState extends ConsumerState<WorkoutCompletionShareScreen> {
  VideoPlayerController? _controller;
  bool _isSharing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      if (widget.videoPath != null && File(widget.videoPath!).existsSync()) {
        _controller = VideoPlayerController.file(File(widget.videoPath!));
      } else if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
      }
      if (_controller != null) {
        await _controller!.initialize();
        await _controller!.setLooping(true);
        await _controller!.play();
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleShare({required bool isPublic}) async {
    setState(() => isPublic ? _isSharing = true : _isSaving = true);
    final repo = ref.read(exploreReelsRepositoryProvider);

    try {
      Uint8List bytes = Uint8List(0);
      if (widget.videoPath != null && File(widget.videoPath!).existsSync()) {
        bytes = await File(widget.videoPath!).readAsBytes();
      }
      if (bytes.isEmpty) {
        bytes = Uint8List.fromList(List.generate(100, (i) => i % 256));
      }

      final uploadedUrl = await repo.uploadVideoFile(userId: 'usr_me', bytes: bytes, fileExtension: 'mp4') ??
          (widget.videoUrl ?? 'https://storage.supabase.co/reels/sample.mp4');

      await repo.publishWorkoutReel(
        tenantId: 'tenant_default',
        userId: 'usr_me',
        videoUrl: uploadedUrl,
        routineTitle: widget.routineTitle,
        durationSeconds: 15,
        isPublic: isPublic,
      );

      if (isPublic) ref.read(exploreReelsProvider.notifier).loadReels();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isPublic ? Theme.of(context).colorScheme.primary : AppColors.surface,
            content: Text(
              isPublic ? '🔥 Shared to Community Explore Feed!' : '🔒 Saved to your private workout profile!',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isPublic ? Colors.black : Colors.white),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload error: $e')));
    } finally {
      if (mounted) setState(() { _isSharing = false; _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('WORKOUT RECORDED! 🎥', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: accent)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Expanded(child: WorkoutVideoLoopCard(controller: _controller, accent: accent)),
              const SizedBox(height: 12),
              Text('${widget.routineTitle.toUpperCase()} • ${widget.totalSets} SETS • ${widget.totalReps} REPS', style: GoogleFonts.oswald(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 16),
              WorkoutShareActionBar(
                onShareToCommunity: () => _handleShare(isPublic: true),
                onSaveToProfile: () => _handleShare(isPublic: false),
                onSkip: () => Navigator.of(context).pop(),
                isSharing: _isSharing,
                isSaving: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
