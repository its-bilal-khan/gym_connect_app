import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/excel_import_service.dart';

class MemberEmptyStateCard extends StatelessWidget {
  final VoidCallback onUploadExcel;
  final VoidCallback onAddMember;

  const MemberEmptyStateCard({
    super.key,
    required this.onUploadExcel,
    required this.onAddMember,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.05),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.groups_rounded, size: 48, color: accent),
            ),
            const SizedBox(height: 20),
            Text(
              'NO GYM MEMBERS REGISTERED YET',
              style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Your live database has zero members. Upload an existing Excel or CSV spreadsheet (.xlsx, .xls, .csv) with auto column matching, or register your first member manually.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: Text('Upload Excel / CSV Sheet', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                  onPressed: onUploadExcel,
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: Text('Register Member', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  onPressed: onAddMember,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              icon: const Icon(Icons.download_rounded, size: 15),
              label: Text('Copy Sample Spreadsheet Template (Headers)', style: GoogleFonts.inter(fontSize: 11)),
              onPressed: () {
                final template = ExcelImportService.generateSampleCsvTemplate();
                Clipboard.setData(ClipboardData(text: template));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sample CSV template copied to clipboard! Paste into Excel or Notepad.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
