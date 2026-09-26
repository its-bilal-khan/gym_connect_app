import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class ProtocolStudioHeader extends StatelessWidget {
  final bool isCustomOverride;
  final bool isPlatformMasterMode;
  final bool isDirty;
  final bool isSaving;
  final String? tenantId;
  final VoidCallback onResetToDefault;
  final VoidCallback onSave;
  final ValueChanged<bool>? onToggleMasterMode;
  final VoidCallback? onBack;

  const ProtocolStudioHeader({
    super.key,
    required this.isCustomOverride,
    required this.isPlatformMasterMode,
    required this.isDirty,
    required this.isSaving,
    this.tenantId,
    required this.onResetToDefault,
    required this.onSave,
    this.onToggleMasterMode,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTitleAndBadge(context)),
          const SizedBox(width: 16),
          // Live Cloud Sync Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSaving
                  ? Colors.amber.withValues(alpha: 0.12)
                  : (isDirty ? Colors.orange.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSaving
                    ? Colors.amber.withValues(alpha: 0.4)
                    : (isDirty ? Colors.orange.withValues(alpha: 0.4) : AppColors.primary.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSaving)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                  )
                else
                  Icon(
                    isDirty ? Icons.cloud_queue_rounded : Icons.cloud_done_rounded,
                    size: 15,
                    color: isDirty ? Colors.orangeAccent : AppColors.primary,
                  ),
                const SizedBox(width: 6),
                Text(
                  isSaving ? 'AUTO-SAVING...' : (isDirty ? 'UNSAVED' : 'SAVED TO CLOUD'),
                  style: GoogleFonts.oswald(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: isSaving ? Colors.amber : (isDirty ? Colors.orangeAccent : AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isCustomOverride && !isPlatformMasterMode) ...[
            OutlinedButton.icon(
              onPressed: isSaving ? null : onResetToDefault,
              icon: const Icon(Icons.restore_rounded, size: 16, color: AppColors.error),
              label: const Text('Reset to Platform Default'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
          ],
          ElevatedButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Icon(Icons.cloud_upload_rounded, size: 18),
            label: Text(isPlatformMasterMode ? 'Save Platform Master' : 'Save Gym Protocol'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleAndBadge(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Back to Dashboard',
          child: OutlinedButton.icon(
            onPressed: () {
              if (onBack != null) {
                onBack!();
              } else if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            icon: Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.primary),
            label: Text(
              'Back',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.background,
              side: const BorderSide(color: AppColors.border, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'WORKOUT PROTOCOL STUDIO',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.oswald(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildBadge(),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                isPlatformMasterMode
                    ? 'Editing Universal Master Protocol (applies to all gyms without custom overrides)'
                    : 'Desktop POS Routine Studio • Overriding workout split for this gym only',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge() {
    final isCustom = isCustomOverride && !isPlatformMasterMode;
    final color = isCustom ? AppColors.primary : const Color(0xFF60A5FA);
    final label = isPlatformMasterMode
        ? 'UNIVERSAL MASTER PLATFORM'
        : (isCustom ? 'GYM CUSTOM OVERRIDE' : 'USING MASTER DEFAULT');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}
