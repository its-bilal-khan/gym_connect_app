import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/musclewiki_service.dart';
import '../../domain/models/cdn_video_item.dart';
import '../../domain/models/workout_models.dart';
import 'fullscreen_video_dialog.dart';

enum MuscleWikiAngleMode {
  frontOnly,
  dualAngle,
}

class MuscleWikiVideoPickerDialog extends StatefulWidget {
  final String? initialSearch;
  final String? initialMuscle;
  final MuscleWikiService service;

  MuscleWikiVideoPickerDialog({
    super.key,
    this.initialSearch,
    this.initialMuscle,
    MuscleWikiService? service,
  }) : service = service ?? MuscleWikiService();

  static Future<CdnVideoItem?> show(
    BuildContext context, {
    String? initialSearch,
    String? initialMuscle,
    MuscleWikiService? service,
  }) {
    return showDialog<CdnVideoItem>(
      context: context,
      builder: (_) => MuscleWikiVideoPickerDialog(
        initialSearch: initialSearch,
        initialMuscle: initialMuscle,
        service: service,
      ),
    );
  }

  @override
  State<MuscleWikiVideoPickerDialog> createState() =>
      _MuscleWikiVideoPickerDialogState();
}

class _MuscleWikiVideoPickerDialogState
    extends State<MuscleWikiVideoPickerDialog> {
  late final TextEditingController _searchCtrl;
  Timer? _debounceTimer;

  String _selectedMuscle = 'All';
  String _selectedCategory = 'All';
  String _selectedGender = 'male';
  MuscleWikiAngleMode _angleMode = MuscleWikiAngleMode.frontOnly;
  bool _isGridView = true;

  List<MuscleWikiExercise> _results = [];
  bool _isLoading = false;
  String? _currentApiKey;

  static const _muscles = [
    'All',
    'Chest',
    'Biceps',
    'Triceps',
    'Back',
    'Shoulders',
    'Legs',
    'Core',
  ];

  static const _categories = [
    'All',
    'Barbell',
    'Dumbbell',
    'Cable',
    'Machine',
    'Bodyweight',
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialSearch ?? '');
    if (widget.initialMuscle != null &&
        _muscles.any((m) => m.toLowerCase() == widget.initialMuscle!.toLowerCase())) {
      _selectedMuscle = widget.initialMuscle!;
    }
    _loadApiKeyAndSearch();
  }

  Future<void> _loadApiKeyAndSearch() async {
    _currentApiKey = await widget.service.getSavedApiKey();
    if (mounted) setState(() {});
    _executeSearch();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _executeSearch();
    });
  }

  Future<void> _executeSearch() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final res = await widget.service.searchExercises(
        query: _searchCtrl.text,
        muscle: _selectedMuscle,
        category: _selectedCategory,
        gender: _selectedGender,
      );
      if (mounted) {
        setState(() {
          _results = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openApiKeyDialog() {
    final ctrl = TextEditingController(text: _currentApiKey ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            Icon(Icons.key_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Text(
              'MUSCLEWIKI API KEY',
              style: GoogleFonts.oswald(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your MuscleWiki API Key (format: mw_xxxxxxxx). This key will be securely saved locally.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'mw_xxxxxxxxxxxxxxxxxxxxxxxx',
                hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Get a free/trial key from: api.musclewiki.com/dashboard/api-keys',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              await widget.service.saveApiKey(ctrl.text.trim());
              _currentApiKey = ctrl.text.trim();
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) {
                setState(() {});
                _executeSearch();
              }
            },
            child: Text('Save Key', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _previewVideo(MuscleWikiExercise ex) {
    final frontUrl = ex.getFrontVideoUrl(gender: _selectedGender);
    final sideUrl = _angleMode == MuscleWikiAngleMode.dualAngle
        ? ex.getSideVideoUrl(gender: _selectedGender)
        : null;

    if (frontUrl == null || frontUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No video stream found for this exercise angle'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final tempExercise = Exercise(
      id: 'mw-${ex.id}',
      name: ex.name,
      targetMuscle: ex.primaryMuscles.isNotEmpty ? ex.primaryMuscles.first : 'General',
      equipment: ex.category,
      videoUrl: frontUrl,
      sideVideoUrl: sideUrl,
      tips: ex.steps.isNotEmpty ? ex.steps.join(' ') : 'MuscleWiki demonstration.',
    );
    FullscreenVideoDialog.show(context, tempExercise);
  }

  void _selectExercise(MuscleWikiExercise ex) {
    final frontUrl = ex.getFrontVideoUrl(gender: _selectedGender);
    final sideUrl = _angleMode == MuscleWikiAngleMode.dualAngle
        ? ex.getSideVideoUrl(gender: _selectedGender)
        : null;

    if (frontUrl == null || frontUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No valid video URL for this exercise'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final item = CdnVideoItem(
      id: 'mw-${ex.id}',
      title: ex.name,
      targetMuscle: ex.primaryMuscles.isNotEmpty ? ex.primaryMuscles.first : 'Chest',
      equipment: ex.category,
      primaryVideoUrl: frontUrl,
      sideVideoUrl: sideUrl,
      tips: ex.steps.isNotEmpty ? ex.steps.join(' ') : 'MuscleWiki video demonstration.',
      cdnProvider: 'MuscleWiki API',
      quality: _angleMode == MuscleWikiAngleMode.frontOnly ? 'Front Angle HD' : 'Dual (Front + Side)',
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 840),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildApiKeyBanner(),
              const SizedBox(height: 10),
              _buildSearchBar(),
              const SizedBox(height: 10),
              _buildControlFilters(),
              const SizedBox(height: 12),
              Expanded(child: _buildResultsSection()),
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
                  Icons.videocam_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'MUSCLEWIKI VIDEO SEARCH',
                            style: GoogleFonts.oswald(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '1,900+ HD VIDEOS',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Search 1,900+ exercises with high-speed video demonstrations and front/side angle selector',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _currentApiKey != null && _currentApiKey!.isNotEmpty
                    ? Icons.key_rounded
                    : Icons.key_off_rounded,
                color: _currentApiKey != null && _currentApiKey!.isNotEmpty
                    ? AppColors.primary
                    : Colors.white38,
                size: 20,
              ),
              tooltip: 'Configure MuscleWiki API Key',
              onPressed: _openApiKeyDialog,
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white60),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApiKeyBanner() {
    final hasKey = _currentApiKey != null && _currentApiKey!.isNotEmpty;
    final maskedKey = hasKey && _currentApiKey!.length > 12
        ? '${_currentApiKey!.substring(0, 7)}...${_currentApiKey!.substring(_currentApiKey!.length - 4)}'
        : (_currentApiKey ?? 'Not configured (loaded from .env)');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasKey ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasKey ? Icons.key_rounded : Icons.key_off_rounded,
            size: 16,
            color: hasKey ? AppColors.primary : Colors.white38,
          ),
          const SizedBox(width: 8),
          Text(
            'API KEY: ',
            style: GoogleFonts.oswald(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            maskedKey,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              color: hasKey ? AppColors.primary : Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border:
                  Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.offline_pin_rounded,
                    size: 12, color: Colors.greenAccent),
                const SizedBox(width: 4),
                Text(
                  widget.service.apiCallsSaved > 0
                      ? 'Saved ${widget.service.apiCallsSaved} API calls'
                      : 'Client Cache Active',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _openApiKeyDialog,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Change Key',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      onChanged: _onSearchChanged,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search by exercise name (e.g. Bench Press, Bicep Curl, Squat, Pushdown)...',
        hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, color: Colors.white38, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  _executeSearch();
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildControlFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Angle Option & Gender Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Text(
                'ANGLE MODE:',
                style: GoogleFonts.oswald(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              // Front Only Toggle (User's specific request!)
              InkWell(
                onTap: () => setState(() => _angleMode = MuscleWikiAngleMode.frontOnly),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _angleMode == MuscleWikiAngleMode.frontOnly
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _angleMode == MuscleWikiAngleMode.frontOnly
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: _angleMode == MuscleWikiAngleMode.frontOnly
                            ? Colors.black
                            : Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'SIRF FRONT VIDEO (Front Only)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _angleMode == MuscleWikiAngleMode.frontOnly
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Dual Angle Toggle
              InkWell(
                onTap: () => setState(() => _angleMode = MuscleWikiAngleMode.dualAngle),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _angleMode == MuscleWikiAngleMode.dualAngle
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _angleMode == MuscleWikiAngleMode.dualAngle
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.view_carousel_rounded,
                        size: 14,
                        color: _angleMode == MuscleWikiAngleMode.dualAngle
                            ? Colors.black
                            : Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'FRONT + SIDE DUAL',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _angleMode == MuscleWikiAngleMode.dualAngle
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Gender Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _genderBtn('Male 👨', 'male'),
                    _genderBtn('Female 👩', 'female'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // View mode switch (Rule 5: Grid vs List)
              IconButton(
                icon: Icon(
                  _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Muscle Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _muscles.map((m) {
              final isSel = _selectedMuscle == m;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(m),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.black : Colors.white70,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedMuscle = m);
                    _executeSearch();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        // Equipment / Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((c) {
              final isSel = _selectedCategory == c;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(c),
                  selected: isSel,
                  selectedColor: AppColors.primary.withValues(alpha: 0.25),
                  backgroundColor: AppColors.background,
                  side: BorderSide(
                    color: isSel ? AppColors.primary : AppColors.border,
                  ),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? AppColors.primary : Colors.white60,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedCategory = c);
                    _executeSearch();
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _genderBtn(String label, String value) {
    final isSel = _selectedGender == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedGender = value);
        _executeSearch();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSel ? AppColors.primary : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_results.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Colors.white38),
            const SizedBox(height: 12),
            Text(
              'No exercises found matching "${_searchCtrl.text}"',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching with common terms like "Bench Press", "Curl", "Squat", or "Pushdown".',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_isGridView) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 420,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
        ),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final ex = _results[index];
          return _buildExerciseCard(ex);
        },
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final ex = _results[index];
        return _buildExerciseListTile(ex);
      },
    );
  }

  Widget _buildExerciseCard(MuscleWikiExercise ex) {
    final frontUrl = ex.getFrontVideoUrl(gender: _selectedGender);
    final sideUrl = ex.getSideVideoUrl(gender: _selectedGender);
    final hasFront = frontUrl != null && frontUrl.isNotEmpty;
    final hasSide = sideUrl != null && sideUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ex.name,
                  style: GoogleFonts.oswald(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasFront)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary, width: 0.8),
                  ),
                  child: Text(
                    'FRONT 🎥',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              if (hasSide)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blueAccent, width: 0.8),
                  ),
                  child: Text(
                    'SIDE 🎥',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (ex.primaryMuscles.isNotEmpty)
                _tagBadge(ex.primaryMuscles.first.toUpperCase(), AppColors.primary),
              _tagBadge(ex.category.toUpperCase(), Colors.white60),
              if (ex.difficulty != null)
                _tagBadge(ex.difficulty!.toUpperCase(), Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              ex.steps.isNotEmpty
                  ? ex.steps.first
                  : 'High quality MuscleWiki video demonstration for correct form and posture.',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _previewVideo(ex),
                icon: const Icon(Icons.play_circle_fill_rounded, size: 14),
                label: const Text('Preview'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _selectExercise(ex),
                icon: const Icon(Icons.check_rounded, size: 14),
                label: Text(
                  _angleMode == MuscleWikiAngleMode.frontOnly ? 'Attach Front Video' : 'Attach Dual Video',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseListTile(MuscleWikiExercise ex) {
    final frontUrl = ex.getFrontVideoUrl(gender: _selectedGender);
    final sideUrl = ex.getSideVideoUrl(gender: _selectedGender);
    final hasFront = frontUrl != null && frontUrl.isNotEmpty;
    final hasSide = sideUrl != null && sideUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ex.name,
                      style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    if (hasFront)
                      Text('• Front 🎥', style: GoogleFonts.inter(fontSize: 10, color: AppColors.primary)),
                    if (hasSide)
                      Text(' • Side 🎥', style: GoogleFonts.inter(fontSize: 10, color: Colors.blueAccent)),
                  ],
                ),
                Text(
                  '${ex.primaryMuscles.join(', ')} • ${ex.category} • ${ex.difficulty ?? 'All Levels'}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _previewVideo(ex),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text('Preview', style: TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _selectExercise(ex),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              _angleMode == MuscleWikiAngleMode.frontOnly ? 'Attach Front' : 'Attach Dual',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
