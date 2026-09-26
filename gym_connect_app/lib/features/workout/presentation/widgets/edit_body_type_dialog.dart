import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/user_role.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../data/workout_repository.dart';
import '../../domain/models/workout_models.dart';
import '../providers/body_types_catalog_provider.dart';
import '../providers/workout_protocol_manager_provider.dart';
import 'body_type_shape_gallery_dialog.dart';

class EditBodyTypeDialog extends ConsumerStatefulWidget {
  final BodyTypeInfo info;

  const EditBodyTypeDialog({super.key, required this.info});

  static Future<bool?> show(BuildContext context, BodyTypeInfo info) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditBodyTypeDialog(info: info),
    );
  }

  @override
  ConsumerState<EditBodyTypeDialog> createState() => _EditBodyTypeDialogState();
}

class _EditBodyTypeDialogState extends ConsumerState<EditBodyTypeDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _physiqueCtrl;
  late final TextEditingController _imageCtrl;

  bool _isSaving = false;
  bool _isUploadingImage = false;
  String _uploadStatusMessage = '';
  late List<String> _galleryUrls;
  int _selectedPreviewIndex = 0;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.info.title);
    _subtitleCtrl = TextEditingController(text: widget.info.subtitle);
    _descCtrl = TextEditingController(text: widget.info.description);
    _physiqueCtrl = TextEditingController(text: widget.info.targetPhysique);
    _imageCtrl = TextEditingController();

    // Initialize gallery list from widget.info
    final existingGallery = List<String>.from(widget.info.galleryImages);
    if (widget.info.imageUrl != null &&
        widget.info.imageUrl!.isNotEmpty &&
        !existingGallery.contains(widget.info.imageUrl)) {
      existingGallery.insert(0, widget.info.imageUrl!);
    }
    _galleryUrls = existingGallery;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _descCtrl.dispose();
    _physiqueCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  void _addDirectUrl() {
    final text = _imageCtrl.text.trim();
    if (text.isEmpty) return;
    if (!text.startsWith('http://') && !text.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid HTTP/HTTPS image URL.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_galleryUrls.contains(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This image URL is already in the gallery.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() {
      _galleryUrls.add(text);
      _selectedPreviewIndex = _galleryUrls.length - 1;
      _imageCtrl.clear();
    });
  }

  void _removeGalleryImage(int index) {
    if (index < 0 || index >= _galleryUrls.length) return;
    setState(() {
      _galleryUrls.removeAt(index);
      if (_selectedPreviewIndex >= _galleryUrls.length) {
        _selectedPreviewIndex = _galleryUrls.isEmpty ? 0 : _galleryUrls.length - 1;
      }
    });
  }

  Future<void> _pickAndUploadMultipleImages() async {
    try {
      final picker = ImagePicker();
      final pickedList = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedList.isEmpty) return;

      setState(() {
        _isUploadingImage = true;
        _uploadStatusMessage = 'Uploading 1 of ${pickedList.length} photos...';
      });

      final repo = ref.read(workoutRepositoryProvider);
      int uploadedCount = 0;

      for (int i = 0; i < pickedList.length; i++) {
        final picked = pickedList[i];
        if (mounted) {
          setState(() {
            _uploadStatusMessage = 'Uploading ${i + 1} of ${pickedList.length} photos...';
          });
        }

        final bytes = await picked.readAsBytes();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = picked.name.isNotEmpty
            ? '${timestamp}_${picked.name}'
            : 'body_type_${widget.info.key}_${timestamp}_$i.jpg';
        final mimeType = picked.mimeType ?? 'image/jpeg';

        final publicUrl = await repo.uploadBodyTypeImage(
          bytes: bytes,
          fileName: fileName,
          mimeType: mimeType,
        );

        if (publicUrl != null) {
          uploadedCount++;
          if (mounted) {
            setState(() {
              if (!_galleryUrls.contains(publicUrl)) {
                _galleryUrls.add(publicUrl);
                _selectedPreviewIndex = _galleryUrls.length - 1;
              }
            });
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
        _uploadStatusMessage = '';
      });

      if (uploadedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$uploadedCount target shape photo(s) added! Click "SAVE PROTOCOL INFO" to apply.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload images. Please check Supabase storage or use direct URLs.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _uploadStatusMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selection error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    final auth = ref.read(authNotifierProvider);
    final isAuthorized = (auth is AuthAuthenticated) &&
        (auth.activeRole == UserRole.superAdmin || auth.activeRole == UserRole.owner);

    if (!isAuthorized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Super Admin & Gym Owner can edit protocols.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a protocol title.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final ok = await ref.read(bodyTypesCatalogProvider.notifier).updateBodyType(
          bodyType: widget.info.key,
          title: title,
          subtitle: _subtitleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          targetPhysique: _physiqueCtrl.text.trim(),
          imageUrl: _galleryUrls.isNotEmpty ? _galleryUrls.first : null,
          galleryImages: _galleryUrls,
        );

    // Refresh workout protocol studio provider if active
    final userTenantId = auth.profile.tenantId;
    ref.read(workoutProtocolManagerProvider.notifier).initialize(
          userTenantId: userTenantId,
          bodyType: widget.info.key,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.info.key.toUpperCase()} protocol & target shape photos saved successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save protocol changes. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.tune_rounded, color: accent, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'EDIT ${widget.info.key.toUpperCase()} PROTOCOL',
                              style: GoogleFonts.oswald(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'OWNER & ADMIN ONLY',
                                style: GoogleFonts.oswald(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Customize protocol title, tagline, goal, and the showcase image shown on mobile.',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Target Physique Outcome Photos (Multiple Images Gallery)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.collections_rounded, color: accent, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'TARGET PHYSIQUE OUTCOME PHOTOS (${_galleryUrls.length})',
                                style: GoogleFonts.oswald(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SHOWN IN MOBILE SLIDER',
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
                          Text(
                            'Upload multiple photos showing the exact physique & muscle cuts members will build by following this protocol. Members can tap and slide through all images on mobile.',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                          ),
                          const SizedBox(height: 12),

                          // Live Main Image Preview Box
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 160,
                              width: double.infinity,
                              color: AppColors.surface,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: _galleryUrls.isNotEmpty
                                        ? Image.network(
                                            _galleryUrls[_selectedPreviewIndex.clamp(0, _galleryUrls.length - 1)],
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, error, stackTrace) =>
                                                _buildPlaceholder(widget.info.defaultImageAsset, isError: true),
                                          )
                                        : _buildPlaceholder(widget.info.defaultImageAsset),
                                  ),
                                  if (_isUploadingImage)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(color: accent, strokeWidth: 2.5),
                                              const SizedBox(height: 10),
                                              Text(
                                                _uploadStatusMessage.isNotEmpty
                                                    ? _uploadStatusMessage.toUpperCase()
                                                    : 'UPLOADING PHOTOS TO STORAGE...',
                                                style: GoogleFonts.oswald(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _galleryUrls.isNotEmpty
                                            ? 'Photo ${_selectedPreviewIndex + 1} of ${_galleryUrls.length}'
                                            : 'Default Asset Photo (No custom uploads yet)',
                                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  if (_galleryUrls.isNotEmpty)
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: InkWell(
                                        onTap: () {
                                          final previewInfo = BodyTypeInfo(
                                            key: widget.info.key,
                                            title: _titleCtrl.text.trim().isNotEmpty ? _titleCtrl.text.trim() : widget.info.title,
                                            subtitle: _subtitleCtrl.text.trim(),
                                            description: _descCtrl.text.trim(),
                                            targetPhysique: _physiqueCtrl.text.trim().isNotEmpty ? _physiqueCtrl.text.trim() : widget.info.targetPhysique,
                                            imageUrl: _galleryUrls.first,
                                            galleryImages: _galleryUrls,
                                            defaultImageAsset: widget.info.defaultImageAsset,
                                          );
                                          BodyTypeShapeGalleryDialog.show(context, info: previewInfo, initialIndex: _selectedPreviewIndex);
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: accent,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.fullscreen_rounded, size: 14, color: Colors.black),
                                              const SizedBox(width: 4),
                                              Text(
                                                'TEST SLIDESHOW',
                                                style: GoogleFonts.oswald(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Horizontal Thumbnail Strip
                          if (_galleryUrls.isNotEmpty) ...[
                            Text(
                              'ATTACHED GALLERY (${_galleryUrls.length} PHOTOS) • TAP TO PREVIEW • CLICK (X) TO REMOVE',
                              style: GoogleFonts.oswald(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 76,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _galleryUrls.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 8),
                                itemBuilder: (context, idx) {
                                  final isCurrent = idx == _selectedPreviewIndex;
                                  final imgUrl = _galleryUrls[idx];
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedPreviewIndex = idx),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 74,
                                          height: 74,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isCurrent ? accent : Colors.white24,
                                              width: isCurrent ? 2 : 1,
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Image.network(
                                            imgUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Container(
                                              color: AppColors.surface,
                                              child: const Icon(Icons.broken_image_rounded, size: 20, color: Colors.white38),
                                            ),
                                          ),
                                        ),
                                        if (idx == 0)
                                          Positioned(
                                            bottom: 3,
                                            left: 3,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'COVER',
                                                style: GoogleFonts.oswald(fontSize: 8, color: accent, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () => _removeGalleryImage(idx),
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.black87,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // URL Input with "+ ADD" Button
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _imageCtrl,
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Paste Image Direct URL',
                                    labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                    hintText: 'https://images.unsplash.com/... or web URL',
                                    hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white24),
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    prefixIcon: const Icon(Icons.link_rounded, color: AppColors.textSecondary, size: 18),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: accent, width: 1.5),
                                    ),
                                  ),
                                  onSubmitted: (_) => _addDirectUrl(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  foregroundColor: accent,
                                  side: BorderSide(color: accent.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _addDirectUrl,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: Text(
                                  'ADD URL',
                                  style: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Upload Multiple Images Button from computer/device
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: accent.withValues(alpha: 0.6)),
                                backgroundColor: accent.withValues(alpha: 0.08),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isUploadingImage ? null : _pickAndUploadMultipleImages,
                              icon: _isUploadingImage
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                                    )
                                  : Icon(Icons.add_photo_alternate_rounded, color: accent, size: 18),
                              label: Text(
                                _isUploadingImage
                                    ? _uploadStatusMessage.toUpperCase()
                                    : 'UPLOAD MULTIPLE PHOTOS FROM COMPUTER / DEVICE',
                                style: GoogleFonts.oswald(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Protocol Title
                    _buildField(
                      label: 'Protocol Title',
                      controller: _titleCtrl,
                      hint: 'e.g. ECTOMORPH',
                    ),
                    const SizedBox(height: 14),

                    // Subtitle / Tagline
                    _buildField(
                      label: 'Subtitle / Tagline',
                      controller: _subtitleCtrl,
                      hint: 'e.g. Lean Build • High Calorie Hypertrophy Split',
                    ),
                    const SizedBox(height: 14),

                    // Target Physique Outcome
                    _buildField(
                      label: 'Target Physique Goal (Displayed on Card)',
                      controller: _physiqueCtrl,
                      hint: 'e.g. Outcome: Shredded Athletic V-Taper (6-8% Body Fat)',
                    ),
                    const SizedBox(height: 14),

                    // Description
                    _buildField(
                      label: 'Full Protocol Description',
                      controller: _descCtrl,
                      hint: 'Scientific 6-day split designed for rapid muscle hypertrophy...',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('CANCEL', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _isSaving ? 'SAVING...' : 'SAVE PROTOCOL INFO',
                      style: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String defaultAsset, {bool isError = false}) {
    return Image.asset(
      defaultAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => Container(
        color: AppColors.surface,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isError ? Icons.broken_image_rounded : Icons.fitness_center_rounded, color: AppColors.textSecondary, size: 36),
            const SizedBox(height: 4),
            Text(
              isError ? 'Image URL unreachable (using default asset)' : 'Default Physique Asset',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white24),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
