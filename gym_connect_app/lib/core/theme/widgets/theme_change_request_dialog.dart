import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../app_theme_presets.dart';
import '../app_theme_provider.dart';
import '../../../features/auth/domain/models/user_profile.dart';

class ThemeChangeRequestDialog extends ConsumerStatefulWidget {
  final UserProfile profile;
  final AppThemePreset currentLockedPreset;

  const ThemeChangeRequestDialog({
    super.key,
    required this.profile,
    required this.currentLockedPreset,
  });

  static Future<void> show(
    BuildContext context, {
    required UserProfile profile,
    required AppThemePreset currentLockedPreset,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ThemeChangeRequestDialog(
        profile: profile,
        currentLockedPreset: currentLockedPreset,
      ),
    );
  }

  @override
  ConsumerState<ThemeChangeRequestDialog> createState() => _ThemeChangeRequestDialogState();
}

class _ThemeChangeRequestDialogState extends ConsumerState<ThemeChangeRequestDialog> {
  late AppThemePreset _selectedPreset;
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    // Default to the first preset different from the current locked one
    _selectedPreset = AppThemePreset.values.firstWhere(
      (p) => p != widget.currentLockedPreset,
      orElse: () => AppThemePreset.neonVolt,
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorText = 'Please provide a reason for the brand color change.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final success = await ref.read(appThemeNotifierProvider.notifier).submitThemeChangeRequest(
          tenantId: widget.profile.tenantId ?? '',
          requestedPreset: _selectedPreset,
          reason: reason,
          profile: widget.profile,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              '✓ Theme Change Request submitted for Super Admin review.',
              style: GoogleFonts.inter(color: _selectedPreset.color, fontWeight: FontWeight.bold),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        setState(() => _errorText = 'Failed to submit request. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white10,
                    radius: 20,
                    child: Icon(Icons.edit_note_rounded, color: _selectedPreset.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GENERATE THEME CHANGE REQUEST',
                          style: GoogleFonts.oswald(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.profile.tenantName,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Your brand theme is permanently locked to ${widget.currentLockedPreset.name}. Changing the official color requires generating an administrative change request for audit compliance.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'DESIRED NEW BRAND COLOR',
                style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppThemePreset.values
                    .where((p) => p != widget.currentLockedPreset)
                    .map((preset) {
                  final isSel = _selectedPreset == preset;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: preset.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(preset.shortName),
                      ],
                    ),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedPreset = preset),
                    selectedColor: preset.color.withValues(alpha: 0.2),
                    backgroundColor: AppColors.background,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? preset.color : AppColors.textSecondary,
                    ),
                    side: BorderSide(color: isSel ? preset.color : AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'REASON FOR REBRANDING / CHANGE',
                style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Annual rebrand campaign, seasonal brand refresh...',
                  errorText: _errorText,
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: Text('CANCEL', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedPreset.color,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text('SUBMIT REQUEST', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
