import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/online_exercise_video_service.dart';
import '../../data/youtube_video_utils.dart';
import '../../domain/models/cdn_video_item.dart';
import '../../domain/models/workout_models.dart';
import 'fullscreen_video_dialog.dart';
import 'musclewiki_video_picker_dialog.dart';

enum VideoPickerTab {
  verifiedCdn,
  onlineSearch,
  customUrl,
}

class CdnVideoPickerDialog extends StatefulWidget {
  final String? initialMuscle;

  const CdnVideoPickerDialog({super.key, this.initialMuscle});

  static Future<CdnVideoItem?> show(
    BuildContext context, {
    String? initialMuscle,
  }) {
    return showDialog<CdnVideoItem>(
      context: context,
      builder: (_) => CdnVideoPickerDialog(initialMuscle: initialMuscle),
    );
  }

  @override
  State<CdnVideoPickerDialog> createState() => _CdnVideoPickerDialogState();
}

class _CdnVideoPickerDialogState extends State<CdnVideoPickerDialog> {
  late final TextEditingController _searchCtrl;
  late final TextEditingController _onlineSearchCtrl;
  late final TextEditingController _customTitleCtrl;
  late final TextEditingController _customUrlCtrl;
  late final TextEditingController _customSideUrlCtrl;
  late final TextEditingController _customTipsCtrl;
  late final TextEditingController _customEqCtrl;

  VideoPickerTab _currentTab = VideoPickerTab.verifiedCdn;
  String _selectedMuscle = 'All';

  // Online search state
  List<CdnVideoItem> _onlineResults = [];
  bool _isOnlineLoading = false;
  Timer? _debounceTimer;

  static const _muscles = [
    'All',
    'Chest',
    'Legs',
    'Back',
    'Arms',
    'Shoulders',
    'Core',
    'Full Body',
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _onlineSearchCtrl = TextEditingController();
    _customTitleCtrl = TextEditingController();
    _customUrlCtrl = TextEditingController();
    _customUrlCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _customSideUrlCtrl = TextEditingController();
    _customSideUrlCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _customTipsCtrl = TextEditingController();
    _customEqCtrl = TextEditingController(text: 'Barbell');

    if (widget.initialMuscle != null &&
        _muscles.contains(widget.initialMuscle)) {
      _selectedMuscle = widget.initialMuscle!;
    }

    // Trigger initial online search if tab switched
    _executeOnlineSearch();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    _onlineSearchCtrl.dispose();
    _customTitleCtrl.dispose();
    _customUrlCtrl.dispose();
    _customSideUrlCtrl.dispose();
    _customTipsCtrl.dispose();
    _customEqCtrl.dispose();
    super.dispose();
  }

  void _onOnlineSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _executeOnlineSearch();
    });
  }

  Future<void> _executeOnlineSearch() async {
    if (!mounted) return;
    setState(() => _isOnlineLoading = true);

    try {
      final results = await OnlineExerciseVideoService.instance.searchOnline(
        query: _onlineSearchCtrl.text,
        muscle: _selectedMuscle,
      );
      if (mounted) {
        setState(() {
          _onlineResults = results;
          _isOnlineLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isOnlineLoading = false);
      }
    }
  }

  void _previewCdnVideo(CdnVideoItem item) {
    final tempExercise = Exercise(
      id: item.id,
      name: item.title,
      targetMuscle: item.targetMuscle,
      equipment: item.equipment,
      videoUrl: item.primaryVideoUrl,
      sideVideoUrl: item.sideVideoUrl,
      tips: item.tips,
    );
    FullscreenVideoDialog.show(context, tempExercise);
  }

  void _previewCustomStream() {
    final rawUrl = _customUrlCtrl.text.trim();
    if (rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid video stream URL')),
      );
      return;
    }
    final isYt = YoutubeVideoUtils.isYouTubeUrl(rawUrl);
    final effectiveUrl = isYt
        ? YoutubeVideoUtils.toEmbedUrl(rawUrl, autoPlay: true, loop: true, mute: true)
        : rawUrl;

    final sideRaw = _customSideUrlCtrl.text.trim();
    final effectiveSideUrl = sideRaw.isNotEmpty
        ? (YoutubeVideoUtils.isYouTubeUrl(sideRaw)
            ? YoutubeVideoUtils.toEmbedUrl(sideRaw, autoPlay: true, loop: true, mute: true)
            : sideRaw)
        : null;

    final tempExercise = Exercise(
      id: 'preview-custom',
      name: _customTitleCtrl.text.trim().isEmpty
          ? (isYt ? 'YouTube Exercise Preview' : 'Custom Video Stream')
          : _customTitleCtrl.text.trim(),
      targetMuscle: _selectedMuscle == 'All' ? 'Chest' : _selectedMuscle,
      equipment: _customEqCtrl.text.trim(),
      videoUrl: effectiveUrl,
      sideVideoUrl: effectiveSideUrl,
      tips: _customTipsCtrl.text.trim(),
    );
    FullscreenVideoDialog.show(context, tempExercise);
  }

  void _useCustomStream() {
    final url = _customUrlCtrl.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid video stream URL')),
      );
      return;
    }
    final item = OnlineExerciseVideoService.instance.createCustomItem(
      title: _customTitleCtrl.text.trim(),
      primaryVideoUrl: url,
      sideVideoUrl: _customSideUrlCtrl.text.trim(),
      targetMuscle: _selectedMuscle == 'All' ? 'Chest' : _selectedMuscle,
      equipment: _customEqCtrl.text.trim().isEmpty
          ? 'Custom'
          : _customEqCtrl.text.trim(),
      tips: _customTipsCtrl.text.trim(),
    );
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final verifiedResults = CdnVideoLibrary.search(
      query: _searchCtrl.text,
      muscle: _selectedMuscle,
    );

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildTabSelector(),
              const SizedBox(height: 14),
              _buildMuscleChips(),
              const SizedBox(height: 12),
              Expanded(
                child: switch (_currentTab) {
                  VideoPickerTab.verifiedCdn =>
                    _buildVerifiedCdnTab(verifiedResults),
                  VideoPickerTab.onlineSearch => _buildOnlineSearchTab(),
                  VideoPickerTab.customUrl => _buildCustomUrlTab(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                child: Icon(
                  Icons.cloud_sync_rounded,
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
                      'SEARCH CLOUD CDN VIDEO LIBRARY',
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
                      'Verified ultra-fast streaming videos from jsDelivr & 1,300+ online fitness CDNs',
                      style: GoogleFonts.inter(
                        fontSize: 11,
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

  Future<void> _openMuscleWiki() async {
    final res = await MuscleWikiVideoPickerDialog.show(
      context,
      initialMuscle: widget.initialMuscle,
    );
    if (res != null && mounted) {
      Navigator.of(context).pop(res);
    }
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _tabBtn(
            tab: VideoPickerTab.verifiedCdn,
            icon: Icons.offline_bolt_rounded,
            title: 'VERIFIED CDN (20+)',
            subtitle: 'Instant HD Streams',
          ),
          const SizedBox(width: 4),
          _tabBtn(
            tab: VideoPickerTab.onlineSearch,
            icon: Icons.language_rounded,
            title: 'ONLINE SEARCH (1,300+)',
            subtitle: 'Live Cloud Search',
          ),
          const SizedBox(width: 4),
          _tabBtn(
            tab: VideoPickerTab.customUrl,
            icon: Icons.link_rounded,
            title: 'CUSTOM VIDEO URL',
            subtitle: 'Paste Direct Stream',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: _openMuscleWiki,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MUSCLEWIKI ⚡',
                            style: GoogleFonts.oswald(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Front / Dual Videos',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn({
    required VideoPickerTab tab,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final active = _currentTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _currentTab = tab);
          if (tab == VideoPickerTab.onlineSearch && _onlineResults.isEmpty) {
            _executeOnlineSearch();
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: active ? AppColors.primary : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.oswald(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: active ? AppColors.primary : Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color:
                      active ? AppColors.primary.withValues(alpha: 0.8) : Colors.white38,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMuscleChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _muscles.map((m) {
          final isSelected = _selectedMuscle == m;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(m),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedMuscle = m);
                if (_currentTab == VideoPickerTab.onlineSearch) {
                  _executeOnlineSearch();
                }
              },
              backgroundColor: AppColors.background,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              labelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVerifiedCdnTab(List<CdnVideoItem> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchInput(
          controller: _searchCtrl,
          hint:
              'Search verified library (e.g. Incline Bench, Dips, Cable Fly, Squat)...',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${results.length} verified exercises ($_selectedMuscle)',
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                'High-Speed jsDelivr CDN',
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: results.isEmpty
              ? _buildEmptyState(
                  title: 'No Verified CDN Videos Found',
                  subtitle:
                      'Try switching to the "ONLINE SEARCH" tab to search 1,300+ cloud exercises.',
                )
              : ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildVideoCard(results[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOnlineSearchTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchInput(
          controller: _onlineSearchCtrl,
          hint:
              'Online Search: type any chest/muscle exercise (e.g. Dumbbell Press, Fly, Cable, Pulldown)...',
          onChanged: _onOnlineSearchChanged,
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (_isOnlineLoading) ...[
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Querying 1,300+ online exercises...',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Found ${_onlineResults.length} online results ($_selectedMuscle)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                'Global Open ExerciseDB Cloud',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isOnlineLoading && _onlineResults.isEmpty
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _onlineResults.isEmpty
                  ? _buildEmptyState(
                      title: 'No Online Exercises Found',
                      subtitle:
                          'Try searching with a broader keyword (e.g. "bench", "press", "chest", "curl") or reset the muscle filter.',
                    )
                  : ListView.separated(
                      itemCount: _onlineResults.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildVideoCard(_onlineResults[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCustomUrlTab() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.link_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'ATTACH DIRECT ONLINE VIDEO STREAM',
                  style: GoogleFonts.oswald(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Supports direct MP4, HLS, MOV, animated GIF, or cloud hosting (Supabase, S3, Cloudflare, GitHub, jsDelivr).',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _customFormField(
              label: 'EXERCISE NAME',
              controller: _customTitleCtrl,
              hint: 'e.g. Incline Smith Machine Bench Press',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _customFormField(
                    label: 'EQUIPMENT',
                    controller: _customEqCtrl,
                    hint: 'e.g. Barbell, Dumbbell, Cable',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TARGET MUSCLE',
                        style: GoogleFonts.oswald(
                            fontSize: 11,
                            letterSpacing: 1.1,
                            color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedMuscle == 'All'
                                ? 'Chest'
                                : _selectedMuscle,
                            isExpanded: true,
                            dropdownColor: AppColors.surface,
                            items: _muscles
                                .where((m) => m != 'All')
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(
                                        m,
                                        style: GoogleFonts.inter(
                                            color: Colors.white, fontSize: 13),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedMuscle = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _customFormField(
              label: 'PRIMARY VIDEO STREAM URL *',
              controller: _customUrlCtrl,
              hint: 'https://example.com/videos/chest_press.mp4 or YouTube link',
            ),
            if (YoutubeVideoUtils.isYouTubeUrl(_customUrlCtrl.text.trim()))
              _buildYouTubeCustomBanner(_customUrlCtrl.text.trim()),
            const SizedBox(height: 12),
            _customFormField(
              label: 'SIDE ANGLE VIDEO URL (OPTIONAL)',
              controller: _customSideUrlCtrl,
              hint: 'https://example.com/videos/chest_press_side.mp4 or YouTube link',
            ),
            if (YoutubeVideoUtils.isYouTubeUrl(_customSideUrlCtrl.text.trim()))
              _buildYouTubeCustomBanner(_customSideUrlCtrl.text.trim()),
            const SizedBox(height: 12),
            _customFormField(
              label: 'BIOMECHANICS & FORM TIPS',
              controller: _customTipsCtrl,
              hint: 'e.g. Retract scapulae, touch lower ribcage, 3s eccentric.',
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _previewCustomStream,
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('Test Stream Preview'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _useCustomStream,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Use Custom Stream'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: GoogleFonts.oswald(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _customFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.oswald(
              fontSize: 11, letterSpacing: 1.1, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYouTubeCustomBanner(String url) {
    final videoId = YoutubeVideoUtils.extractVideoId(url);
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(width: 8),
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
                        'COPYRIGHT SAFE EMBED',
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
                  'Auto-converts into official YouTube embed player with Autoplay & Seamless Loop enabled. Zero copyright strike risk via IFrame API.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
                if (videoId != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Video ID: $videoId • Target: youtube-nocookie.com/embed (autoplay=1, mute=1, loop=1)',
                    style: GoogleFonts.robotoMono(
                        fontSize: 10, color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon:
            Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded,
                    color: Colors.white54, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: Colors.white30),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(CdnVideoItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.oswald(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.targetMuscle,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Text(
                          '• ${item.equipment}',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          '• ${item.quality}',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.cyanAccent),
                        ),
                        if (item.sideVideoUrl != null)
                          Text(
                            '• Dual Angle',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.greenAccent),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.primaryVideoUrl,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              color: Colors.white60,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            item.tips,
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(color: AppColors.border, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _previewCdnVideo(item),
                icon: const Icon(Icons.visibility_rounded, size: 16),
                label: const Text('Preview Stream'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(item),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Use This Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: GoogleFonts.oswald(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
