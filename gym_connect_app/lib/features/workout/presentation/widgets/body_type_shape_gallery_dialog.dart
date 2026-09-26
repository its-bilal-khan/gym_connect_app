import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/workout_models.dart';

class BodyTypeShapeGalleryDialog extends StatefulWidget {
  final BodyTypeInfo info;
  final int initialIndex;

  const BodyTypeShapeGalleryDialog({
    super.key,
    required this.info,
    this.initialIndex = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required BodyTypeInfo info,
    int initialIndex = 0,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => BodyTypeShapeGalleryDialog(
        info: info,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  State<BodyTypeShapeGalleryDialog> createState() =>
      _BodyTypeShapeGalleryDialogState();
}

class _BodyTypeShapeGalleryDialogState
    extends State<BodyTypeShapeGalleryDialog> {
  late final PageController _pageController;
  late int _currentIndex;
  late final List<String> _images;

  @override
  void initState() {
    super.initState();
    _images = widget.info.allImages;
    _currentIndex = widget.initialIndex.clamp(0, _images.isEmpty ? 0 : _images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < _images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final totalImages = _images.isEmpty ? 1 : _images.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 860),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Image Slider Area
              Positioned.fill(
                child: _images.isEmpty
                    ? _buildFallbackImage(widget.info.defaultImageAsset)
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: _images.length,
                        onPageChanged: (i) => setState(() => _currentIndex = i),
                        itemBuilder: (context, index) {
                          final imgUrl = _images[index];
                          return InteractiveViewer(
                            minScale: 1.0,
                            maxScale: 3.5,
                            child: Center(
                              child: Image.network(
                                imgUrl,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: accent,
                                      strokeWidth: 2.5,
                                    ),
                                  );
                                },
                                errorBuilder: (_, error, stackTrace) =>
                                    _buildFallbackImage(widget.info.defaultImageAsset),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Gradient Overlay at Top & Bottom for legible controls
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 110,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 180,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.95),
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Top Bar (Title, Counter, Close)
              Positioned(
                top: 16,
                left: 20,
                right: 16,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: accent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.info.key.toUpperCase()} TARGET PHYSIQUE',
                            style: GoogleFonts.oswald(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (totalImages > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / $totalImages',
                          style: GoogleFonts.oswald(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Desktop / Tablet Next & Prev chevron buttons
              if (totalImages > 1) ...[
                if (_currentIndex > 0)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: InkWell(
                        onTap: _prevPage,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                if (_currentIndex < totalImages - 1)
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: InkWell(
                        onTap: _nextPage,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
              ],

              // Bottom Info Card (Physique Goal & Explanation)
              Positioned(
                bottom: 18,
                left: 20,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Target Goal Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accent.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: accent, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.info.targetPhysique,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.oswald(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Follow this protocol split to sculpt this exact physique blueprint. Pinch to zoom & slide to inspect muscle cuts.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    if (totalImages > 1) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(totalImages, (i) {
                          final isActive = i == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 22 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive ? accent : Colors.white24,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage(String defaultAsset) {
    return Center(
      child: Image.asset(
        defaultAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stackTrace) => Container(
          color: AppColors.surface,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fitness_center_rounded, color: AppColors.textSecondary, size: 48),
              const SizedBox(height: 10),
              Text(
                'Default Physique Asset',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
