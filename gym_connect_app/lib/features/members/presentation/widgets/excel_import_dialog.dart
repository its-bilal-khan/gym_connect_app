import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/excel_import_service.dart';
import '../../data/universal_file_picker/universal_spreadsheet_picker.dart';
import '../../domain/models/gym_member.dart';

class ExcelImportDialog extends StatefulWidget {
  final String tenantId;
  final List<GymMember> existingMembers;
  final Function(List<GymMember> validMembers) onConfirmImport;

  const ExcelImportDialog({
    super.key,
    required this.tenantId,
    required this.existingMembers,
    required this.onConfirmImport,
  });

  static Future<void> show(
    BuildContext context, {
    required String tenantId,
    required List<GymMember> existingMembers,
    required Function(List<GymMember> validMembers) onConfirmImport,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ExcelImportDialog(
        tenantId: tenantId,
        existingMembers: existingMembers,
        onConfirmImport: onConfirmImport,
      ),
    );
  }

  @override
  State<ExcelImportDialog> createState() => _ExcelImportDialogState();
}

class _ExcelImportDialogState extends State<ExcelImportDialog> {
  final ExcelImportService _importService = const ExcelImportService();
  final TextEditingController _pasteController = TextEditingController();
  bool _isPasteMode = false;
  bool _isParsing = false;
  String? _selectedFileName;
  String? _errorMessage;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  // Multi-step: 0 = Pick file, 1 = Map Columns & Duplicates, 2 = Preview & Confirm
  int _currentStep = 0;

  RawSheetData? _rawSheet;
  Map<String, int> _userMapping = {};
  bool _updateDuplicates = true;
  ExcelImportResult? _importResult;

  final Map<String, String> _dbFieldLabels = {
    'code': 'Member Code / ID',
    'name': 'Full Name *',
    'phone': 'Phone Number *',
    'email': 'Email Address',
    'plan': 'Membership Plan / Tier',
    'joinDate': 'Join / Admission Date',
    'expiryDate': 'Expiry / Renewal Date',
    'dues': 'Pending Dues (PKR)',
    'password': 'Initial Password / PIN',
    'protocol': 'Assigned Workout Protocol',
  };

  void _pickAndAnalyzeSheet() async {
    try {
      final picked = await pickSpreadsheetFile();
      if (picked == null) return;

      setState(() {
        _isParsing = true;
        _errorMessage = null;
        _selectedFileName = picked.name;
      });

      final rawData = await _importService.extractRawSheetData(
        bytes: picked.bytes,
        fileName: picked.name,
      );

      if (rawData.headers.isEmpty || rawData.rows.isEmpty) {
        setState(() {
          _isParsing = false;
          _errorMessage = 'Spreadsheet is empty or has no data rows.';
        });
        return;
      }

      setState(() {
        _isParsing = false;
        _rawSheet = rawData;
        _userMapping = Map.from(rawData.autoDetectedMapping);
        _currentStep = 1; // Move to column mapping step
      });
    } catch (e) {
      setState(() {
        _isParsing = false;
        _errorMessage = 'Error analyzing file: $e';
      });
    }
  }

  void _analyzePastedText() async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please paste CSV or spreadsheet rows before analyzing.');
      return;
    }

    try {
      setState(() {
        _isParsing = true;
        _errorMessage = null;
        _selectedFileName = 'Pasted Spreadsheet Data';
      });

      final bytes = Uint8List.fromList(utf8.encode(text));
      final rawData = await _importService.extractRawSheetData(
        bytes: bytes,
        fileName: 'pasted_roster.csv',
      );

      if (rawData.headers.isEmpty || rawData.rows.isEmpty) {
        setState(() {
          _isParsing = false;
          _errorMessage = 'Could not parse headers or rows from pasted text. Ensure the first line contains column headers.';
        });
        return;
      }

      setState(() {
        _isParsing = false;
        _rawSheet = rawData;
        _userMapping = Map.from(rawData.autoDetectedMapping);
        _currentStep = 1; // Move to column mapping step
      });
    } catch (e) {
      setState(() {
        _isParsing = false;
        _errorMessage = 'Error analyzing pasted text: $e';
      });
    }
  }

  void _runMappingAndPreview() {
    if (_rawSheet == null) return;

    final processed = _importService.processWithMapping(
      rows: _rawSheet!.rows,
      mapping: _userMapping,
      tenantId: widget.tenantId,
      updateDuplicates: _updateDuplicates,
      existingMembers: widget.existingMembers,
    );

    setState(() {
      _importResult = processed;
      _currentStep = 2; // Move to preview step
    });
  }

  void _copySampleTemplate() {
    final csv = ExcelImportService.generateSampleCsvTemplate();
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sample CSV template copied to clipboard! Paste into Excel or Notepad.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(accent),
              const Divider(color: AppColors.border, height: 24),
              _buildStepperTabs(accent),
              const SizedBox(height: 16),
              Expanded(
                child: _isParsing
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: accent),
                            const SizedBox(height: 14),
                            Text('Analyzing columns and mapping database fields...', style: GoogleFonts.inter(color: Colors.white)),
                          ],
                        ),
                      )
                    : _buildStepContent(accent),
              ),
              const Divider(color: AppColors.border, height: 24),
              _buildBottomActions(accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.table_view_rounded, color: accent, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXCEL & CSV MEMBERS INGESTION ENGINE',
                  style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1),
                ),
                Text(
                  'Smart column matching, automated account generation & duplicate resolution',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildStepperTabs(Color accent) {
    return Row(
      children: [
        _buildStepBadge(0, '1. Select File', accent),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        _buildStepBadge(1, '2. Column Mapping & Duplicates', accent),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        _buildStepBadge(2, '3. Preview & Commit', accent),
      ],
    );
  }

  Widget _buildStepBadge(int stepIndex, String title, Color accent) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? accent.withValues(alpha: 0.15) : (isDone ? Colors.white10 : AppColors.background),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? accent : (isDone ? Colors.greenAccent : AppColors.border)),
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? accent : (isDone ? Colors.greenAccent : AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildStepContent(Color accent) {
    if (_currentStep == 0) {
      return _buildFilePickerStep(accent);
    } else if (_currentStep == 1) {
      return _buildMappingStep(accent);
    } else {
      return _buildPreviewStep(accent);
    }
  }

  Widget _buildFilePickerStep(Color accent) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode Selector: Upload File vs Paste Directly
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => setState(() => _isPasteMode = false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isPasteMode ? accent.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.upload_file_rounded, size: 16, color: !_isPasteMode ? accent : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Upload Spreadsheet File',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: !_isPasteMode ? accent : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => setState(() => _isPasteMode = true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isPasteMode ? accent.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.content_paste_rounded, size: 16, color: _isPasteMode ? accent : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Paste CSV / Excel Text',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isPasteMode ? accent : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (!_isPasteMode) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.upload_file_rounded, size: 42, color: accent),
              ),
              const SizedBox(height: 12),
              Text(
                'Upload Gym Members Spreadsheet',
                style: GoogleFonts.oswald(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Supports .xlsx, .xls, or .csv. Headers will be auto-matched to database fields.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: Text('Browse Spreadsheet File', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _isParsing ? null : _pickAndAnalyzeSheet,
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: Text('Copy Sample Template Header', style: GoogleFonts.inter(fontSize: 12)),
                    onPressed: _copySampleTemplate,
                  ),
                ],
              ),
            ] else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Paste Copied Rows from Excel, Google Sheets, or CSV:',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pasteController,
                maxLines: 6,
                style: GoogleFonts.robotoMono(fontSize: 11, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Member Code,Full Name,Phone Number,Email,Plan,Join Date,Expiry Date,Dues\nGC-M-1001,Hamza Tariq,+923001234567,hamza@example.com,Annual VIP,2026-01-01,2027-01-01,0',
                  hintStyle: GoogleFonts.robotoMono(fontSize: 10, color: Colors.white30),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accent)),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: Text('Parse & Map Columns', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _isParsing ? null : _analyzePastedText,
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.paste_rounded, size: 16),
                    label: Text('Fill Sample Template Data', style: GoogleFonts.inter(fontSize: 12)),
                    onPressed: () {
                      _pasteController.text = ExcelImportService.generateSampleCsvTemplate();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ],

            if (_isParsing) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: accent)),
                  const SizedBox(width: 10),
                  Text('Analyzing spreadsheet & auto-detecting columns...', style: GoogleFonts.inter(fontSize: 12, color: accent)),
                ],
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 16, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(_errorMessage!, style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMappingStep(Color accent) {
    final raw = _rawSheet!;
    final sheetHeaders = ['[Do Not Import]', ...raw.headers];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Duplicate Handling Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.sync_problem_rounded, color: accent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DUPLICATE MEMBER RESOLUTION', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(
                        _updateDuplicates
                            ? 'Update & Overwrite: Existing members with matching phone/email will be refreshed with new plan/dues/expiry dates.'
                            : 'Skip Duplicates: Existing members will not be overwritten.',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _updateDuplicates,
                  activeThumbColor: accent,
                  onChanged: (v) => setState(() => _updateDuplicates = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'CONFIRM DATABASE COLUMN MAPPING',
            style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          Text(
            'The engine auto-detected matches from ${_selectedFileName ?? "file"}. Adjust any dropdown if needed:',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Mapping Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dbFieldLabels.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 12,
              childAspectRatio: 3.4,
            ),
            itemBuilder: (context, index) {
              final key = _dbFieldLabels.keys.elementAt(index);
              final label = _dbFieldLabels[key]!;
              final currentIdx = _userMapping[key] ?? -1;
              final selectedHeader = currentIdx >= 0 && currentIdx < raw.headers.length ? raw.headers[currentIdx] : '[Do Not Import]';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: sheetHeaders.contains(selectedHeader) ? selectedHeader : '[Do Not Import]',
                        isDense: true,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        style: GoogleFonts.inter(fontSize: 11, color: accent),
                        items: sheetHeaders.map((h) => DropdownMenuItem(value: h, child: Text(h, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (newVal) {
                          setState(() {
                            if (newVal == null || newVal == '[Do Not Import]') {
                              _userMapping.remove(key);
                            } else {
                              final mappedIdx = raw.headers.indexOf(newVal);
                              if (mappedIdx != -1) _userMapping[key] = mappedIdx;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep(Color accent) {
    final res = _importResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildBadge('Total Rows: ${res.totalRowsDetected}', Colors.white70),
            const SizedBox(width: 8),
            _buildBadge('New Registrations: ${res.newCount}', Colors.greenAccent),
            const SizedBox(width: 8),
            _buildBadge('Updated Existing: ${res.updatedCount}', Colors.lightBlueAccent),
            const SizedBox(width: 8),
            if (res.hasIssues) _buildBadge('Warnings / Skipped: ${res.issueCount}', Colors.orangeAccent),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.surface),
                    columnSpacing: 20,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 46,
                    columns: const [
                      DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Plan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Expiry', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Pending Dues', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Temp Password', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Assigned Protocol', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    ],
                    rows: res.validMembers.map((m) {
                      return DataRow(cells: [
                        DataCell(Text(m.memberCode, style: GoogleFonts.oswald(fontWeight: FontWeight.bold, color: accent))),
                        DataCell(Text(m.fullName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white))),
                        DataCell(Text(m.phone, style: GoogleFonts.inter(color: Colors.white70))),
                        DataCell(Text(m.email, style: GoogleFonts.inter(color: AppColors.textSecondary))),
                        DataCell(Text(m.planName, style: GoogleFonts.inter(color: Colors.white70))),
                        DataCell(Text(m.expiryDate.toIso8601String().split('T').first, style: GoogleFonts.inter(color: Colors.white70))),
                        DataCell(Text('PKR ${m.duesAmount.toStringAsFixed(0)}', style: GoogleFonts.inter(color: m.isDuesOverdue ? Colors.redAccent : Colors.white70))),
                        DataCell(Text(m.tempPassword, style: GoogleFonts.inter(color: Colors.cyanAccent))),
                        DataCell(Text(m.assignedProtocol, style: GoogleFonts.inter(color: Colors.white70))),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: Text('Back', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => setState(() => _currentStep--),
          )
        else
          const SizedBox.shrink(),
        Row(
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            if (_currentStep == 1)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.preview_rounded, size: 16),
                label: Text('Verify & Preview Rows', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: _runMappingAndPreview,
              )
            else if (_currentStep == 2)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                label: Text(
                  'Commit Ingestion (${_importResult?.successCount ?? 0} Members)',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: (_importResult != null && _importResult!.validMembers.isNotEmpty)
                    ? () {
                        widget.onConfirmImport(_importResult!.validMembers);
                        Navigator.of(context).pop();
                      }
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
