import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/workout_models.dart';
import '../../widgets/exercise_video_preview_thumbnail.dart';

class ExerciseCatalogPickerDialog extends StatefulWidget {
  final List<Exercise> catalog;
  final ValueChanged<Exercise> onExerciseSelected;

  const ExerciseCatalogPickerDialog({
    super.key,
    required this.catalog,
    required this.onExerciseSelected,
  });

  static Future<Exercise?> show(
    BuildContext context, {
    required List<Exercise> catalog,
  }) {
    return showDialog<Exercise>(
      context: context,
      builder: (ctx) => ExerciseCatalogPickerDialog(
        catalog: catalog,
        onExerciseSelected: (ex) => Navigator.of(ctx).pop(ex),
      ),
    );
  }

  @override
  State<ExerciseCatalogPickerDialog> createState() =>
      _ExerciseCatalogPickerDialogState();
}

class _ExerciseCatalogPickerDialogState
    extends State<ExerciseCatalogPickerDialog> {
  String _searchQuery = '';
  String _selectedMuscle = 'All';
  bool _isGridView = false;

  final List<String> _muscleFilters = const [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = widget.catalog.where((ex) {
      final matchesSearch = _searchQuery.isEmpty ||
          ex.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ex.targetMuscle.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMuscle = _selectedMuscle == 'All' ||
          ex.targetMuscle.toLowerCase().contains(_selectedMuscle.toLowerCase());
      return matchesSearch && matchesMuscle;
    }).toList();

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildMuscleFilterChips(),
              const SizedBox(height: 16),
              Expanded(child: _buildExerciseList(filtered)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EXERCISE CATALOG',
                style: GoogleFonts.oswald(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select an exercise to add to the daily routine split',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _toggleIconBtn(
                    icon: Icons.view_list_rounded,
                    active: !_isGridView,
                    tooltip: 'List View',
                    onTap: () => setState(() => _isGridView = false),
                  ),
                  const SizedBox(width: 4),
                  _toggleIconBtn(
                    icon: Icons.grid_view_rounded,
                    active: _isGridView,
                    tooltip: 'Grid View',
                    onTap: () => setState(() => _isGridView = true),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _toggleIconBtn({
    required IconData icon,
    required bool active,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? Colors.black : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search by exercise name or target muscle...',
        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
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
      ),
    );
  }

  Widget _buildMuscleFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _muscleFilters.map((m) {
          final isSelected = _selectedMuscle == m;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(m),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedMuscle = m),
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
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExerciseList(List<Exercise> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Text(
          'No exercises match your search',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
      );
    }

    if (_isGridView) {
      return GridView.builder(
        itemCount: exercises.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 330,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 195,
        ),
        itemBuilder: (context, index) {
          final ex = exercises[index];
          final hasVideo = ex.videoUrl != null && ex.videoUrl!.isNotEmpty;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ex.targetMuscle} • ${ex.equipment}',
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
                const SizedBox(height: 8),
                if (hasVideo)
                  ExerciseVideoPreviewThumbnail(
                    exercise: ex,
                    height: 75,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(8),
                  )
                else
                  Container(
                    height: 75,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(
                        'No Video Attached',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ex.difficulty.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => widget.onExerciseSelected(ex),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, size: 14, color: Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              'ADD',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    return ListView.separated(
      itemCount: exercises.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final ex = exercises[index];
        final hasVideo = ex.videoUrl != null && ex.videoUrl!.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            leading: hasVideo
                ? ExerciseVideoPreviewThumbnail(
                    exercise: ex,
                    width: 72,
                    height: 48,
                    borderRadius: BorderRadius.circular(6),
                  )
                : null,
            title: Text(
              ex.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              '${ex.targetMuscle} • ${ex.equipment} • ${ex.difficulty}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: ElevatedButton.icon(
              onPressed: () => widget.onExerciseSelected(ex),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
