import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xl;
import '../domain/models/gym_member.dart';

class ExcelRowIssue {
  final int rowIndex;
  final String rawIdentifier;
  final String issueDescription;

  const ExcelRowIssue({
    required this.rowIndex,
    required this.rawIdentifier,
    required this.issueDescription,
  });
}

class RawSheetData {
  final List<String> headers;
  final List<List<dynamic>> rows;
  final Map<String, int> autoDetectedMapping;

  const RawSheetData({
    required this.headers,
    required this.rows,
    required this.autoDetectedMapping,
  });
}

class ExcelImportResult {
  final List<GymMember> validMembers;
  final List<ExcelRowIssue> issues;
  final int totalRowsDetected;
  final int updatedCount;
  final int newCount;

  const ExcelImportResult({
    required this.validMembers,
    required this.issues,
    required this.totalRowsDetected,
    this.updatedCount = 0,
    this.newCount = 0,
  });

  int get successCount => validMembers.length;
  int get issueCount => issues.length;
  bool get hasIssues => issues.isNotEmpty;
}

class ExcelImportService {
  const ExcelImportService();

  /// Extracts headers, rows, and auto-detects column mapping
  Future<RawSheetData> extractRawSheetData({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final lowerName = fileName.toLowerCase();
    List<String> headers = [];
    List<List<dynamic>> dataRows = [];

    if (lowerName.endsWith('.csv') || lowerName.endsWith('.txt') || lowerName.endsWith('.tsv') || lowerName.contains('paste')) {
      final rawString = utf8.decode(bytes, allowMalformed: true);
      final firstLine = rawString.split(RegExp(r'\r?\n')).firstOrNull ?? '';
      final isTabSeparated = firstLine.contains('\t');

      if (isTabSeparated) {
        final lines = rawString.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
        if (lines.isNotEmpty) {
          headers = lines.first.split('\t').map((e) => e.trim()).toList();
          dataRows = lines.skip(1).map((l) => l.split('\t').map((e) => e.trim()).toList()).toList();
        }
      } else {
        final rows = Csv().decode(rawString);
        if (rows.isNotEmpty) {
          headers = rows.first.map((e) => e.toString().trim()).toList();
          dataRows = rows.skip(1).toList();
        }
      }
    } else {
      final excel = xl.Excel.decodeBytes(bytes);
      if (excel.tables.isNotEmpty) {
        final firstKey = excel.tables.keys.firstWhere(
          (k) => (excel.tables[k]?.maxRows ?? 0) > 0,
          orElse: () => excel.tables.keys.first,
        );
        final table = excel.tables[firstKey];
        if (table != null && table.rows.isNotEmpty) {
          headers = table.rows.first.map((c) => c?.value?.toString().trim() ?? '').toList();
          for (int i = 1; i < table.rows.length; i++) {
            dataRows.add(table.rows[i].map((c) => c?.value?.toString().trim() ?? '').toList());
          }
        }
      }
    }

    final autoMap = detectColumnMapping(headers);
    return RawSheetData(
      headers: headers,
      rows: dataRows,
      autoDetectedMapping: autoMap,
    );
  }

  /// Auto detects mapping from header strings
  Map<String, int> detectColumnMapping(List<String> headers) {
    final Map<String, int> map = {};

    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      if (h.contains('code') || h.contains('memberid') || h.contains('card') || h.contains('roll') || h.contains('id')) {
        map['code'] ??= i;
      } else if (h.contains('name') || h.contains('client')) {
        map['name'] ??= i;
      } else if (h.contains('phone') || h.contains('mobile') || h.contains('cell') || h.contains('whatsapp') || h.contains('contact')) {
        map['phone'] ??= i;
      } else if (h.contains('email') || h.contains('mail')) {
        map['email'] ??= i;
      } else if (h.contains('plan') || h.contains('package') || h.contains('tier') || h.contains('type')) {
        map['plan'] ??= i;
      } else if (h.contains('join') || h.contains('start') || h.contains('admission') || h.contains('register')) {
        map['joinDate'] ??= i;
      } else if (h.contains('expir') || h.contains('end') || h.contains('valid') || h.contains('renew')) {
        map['expiryDate'] ??= i;
      } else if (h.contains('dues') || h.contains('fee') || h.contains('balance') || h.contains('amount')) {
        map['dues'] ??= i;
      } else if (h.contains('pass') || h.contains('pin') || h.contains('login')) {
        map['password'] ??= i;
      } else if (h.contains('workout') || h.contains('protocol') || h.contains('routine')) {
        map['protocol'] ??= i;
      }
    }

    return map;
  }

  /// Applies mapping configuration, performs duplicate resolution, and parses members
  ExcelImportResult processWithMapping({
    required List<List<dynamic>> rows,
    required Map<String, int> mapping,
    required String tenantId,
    required bool updateDuplicates,
    required List<GymMember> existingMembers,
  }) {
    final List<GymMember> results = [];
    final List<ExcelRowIssue> issues = [];

    final Map<String, GymMember> existingByPhone = {};
    final Map<String, GymMember> existingByEmail = {};
    final Map<String, GymMember> existingByCode = {};

    for (final m in existingMembers) {
      if (m.phone.isNotEmpty) existingByPhone[m.phone] = m;
      if (m.email.isNotEmpty) existingByEmail[m.email.toLowerCase()] = m;
      if (m.memberCode.isNotEmpty) existingByCode[m.memberCode.toUpperCase()] = m;
    }

    int newCount = 0;
    int updatedCount = 0;
    int rowIndex = 1;

    for (final row in rows) {
      rowIndex++;
      final isRowEmpty = row.every((c) => c == null || c.toString().trim().isEmpty);
      if (isRowEmpty) continue;

      String getVal(String key) {
        final idx = mapping[key];
        if (idx == null || idx < 0 || idx >= row.length) return '';
        return row[idx]?.toString().trim() ?? '';
      }

      final rawName = getVal('name');
      final rawCode = getVal('code');
      final rawPhone = _normalizePhone(getVal('phone'));
      final rawEmail = getVal('email').toLowerCase();
      final rawPlan = getVal('plan');
      final rawJoinDate = getVal('joinDate');
      final rawExpiryDate = getVal('expiryDate');
      final rawDues = getVal('dues');
      final rawPassword = getVal('password');
      final rawProtocol = getVal('protocol');

      if (rawName.isEmpty) {
        issues.add(ExcelRowIssue(
          rowIndex: rowIndex,
          rawIdentifier: rawCode.isNotEmpty ? rawCode : 'Row #$rowIndex',
          issueDescription: 'Skipped: Member name is required.',
        ));
        continue;
      }

      final effectiveCode = rawCode.isNotEmpty
          ? rawCode.toUpperCase()
          : 'GC-M-${1000 + rowIndex + results.length}';

      final effectiveEmail = rawEmail.isNotEmpty
          ? rawEmail
          : '${effectiveCode.toLowerCase()}@gymconnect.internal';

      // Check duplicates
      final existing = existingByPhone[rawPhone] ??
          existingByEmail[effectiveEmail] ??
          existingByCode[effectiveCode];

      if (existing != null) {
        if (!updateDuplicates) {
          issues.add(ExcelRowIssue(
            rowIndex: rowIndex,
            rawIdentifier: '$rawName ($effectiveCode)',
            issueDescription: 'Skipped: Duplicate member ($rawPhone / $effectiveEmail) already in system.',
          ));
          continue;
        } else {
          // Update existing member record
          final joinDate = _parseDate(rawJoinDate) ?? existing.joinDate;
          final expiryDate = _parseDate(rawExpiryDate) ?? existing.expiryDate;
          final double dues = double.tryParse(rawDues.replaceAll(RegExp(r'[^0-9.]'), '')) ?? existing.duesAmount;

          final updated = existing.copyWith(
            fullName: rawName,
            phone: rawPhone.isNotEmpty ? rawPhone : existing.phone,
            email: effectiveEmail,
            planName: rawPlan.isNotEmpty ? rawPlan : existing.planName,
            joinDate: joinDate,
            expiryDate: expiryDate,
            duesAmount: dues,
            duesStatus: dues > 0 ? MemberDuesStatus.unpaid : MemberDuesStatus.paid,
            tempPassword: rawPassword.isNotEmpty ? rawPassword : existing.tempPassword,
            assignedProtocol: rawProtocol.isNotEmpty ? rawProtocol : existing.assignedProtocol,
            updatedByStaff: 'Bulk Sheet Ingestion (Auto-Update)',
          );

          results.add(updated);
          updatedCount++;
          continue;
        }
      }

      // New Member
      final joinDate = _parseDate(rawJoinDate) ?? DateTime.now();
      final expiryDate = _parseDate(rawExpiryDate) ?? joinDate.add(const Duration(days: 30));
      final double dues = double.tryParse(rawDues.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      final tempPass = rawPassword.isNotEmpty
          ? rawPassword
          : 'Gym@${effectiveCode.replaceAll(RegExp(r'[^0-9]'), '').padLeft(4, '0')}';
      final protocol = rawProtocol.isNotEmpty
          ? rawProtocol
          : 'Mesomorph: Athletic Power & V-Taper';

      final newMember = GymMember(
        id: 'imported-$rowIndex-${DateTime.now().millisecondsSinceEpoch}',
        tenantId: tenantId,
        memberCode: effectiveCode,
        fullName: rawName,
        phone: rawPhone,
        email: effectiveEmail,
        planName: rawPlan.isNotEmpty ? rawPlan : 'Standard Gym Access',
        joinDate: joinDate,
        expiryDate: expiryDate,
        duesAmount: dues,
        duesStatus: dues > 0 ? MemberDuesStatus.unpaid : MemberDuesStatus.paid,
        status: expiryDate.isBefore(DateTime.now()) ? MemberAccountStatus.expired : MemberAccountStatus.active,
        tempPassword: tempPass,
        assignedProtocol: protocol,
        currentStreakDays: 1,
        totalCheckIns: 1,
        lastCheckIn: DateTime.now().subtract(const Duration(hours: 4)),
        updatedByStaff: 'Bulk Sheet Ingestion (New)',
      );

      results.add(newMember);
      newCount++;
    }

    return ExcelImportResult(
      validMembers: results,
      issues: issues,
      totalRowsDetected: rows.length,
      updatedCount: updatedCount,
      newCount: newCount,
    );
  }

  String _normalizePhone(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('03')) {
      return '+92${cleaned.substring(1)}';
    }
    return cleaned;
  }

  DateTime? _parseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    final direct = DateTime.tryParse(raw);
    if (direct != null) return direct;

    final parts = raw.split(RegExp(r'[/.-]'));
    if (parts.length == 3) {
      final p1 = int.tryParse(parts[0]);
      final p2 = int.tryParse(parts[1]);
      final p3 = int.tryParse(parts[2]);
      if (p1 != null && p2 != null && p3 != null) {
        if (p3 > 1900) return DateTime(p3, p2, p1);
        if (p1 > 1900) return DateTime(p1, p2, p3);
      }
    }
    return null;
  }

  static String generateSampleCsvTemplate() {
    const headers = [
      'Member Code',
      'Full Name',
      'Phone Number',
      'Email',
      'Membership Plan',
      'Join Date (YYYY-MM-DD)',
      'Expiry Date (YYYY-MM-DD)',
      'Pending Dues (PKR)',
      'Initial Password',
      'Assigned Workout Protocol'
    ];

    const sampleRows = [
      'GC-M-1011,Hamza Tariq,+923001234567,hamza@example.com,Annual VIP Access,2026-01-15,2027-01-15,0,Gym@1011,Mesomorph: Athletic Power & V-Taper',
      'GC-M-1012,Bilal Ahmed,+923219876543,bilal@example.com,Monthly Fitness,2026-08-01,2026-09-01,2500,Gym@1012,Ectomorph: Lean Bulk Mass',
      'GC-M-1013,Zainab Malik,+923334445566,zainab@example.com,Quarterly Shred,2026-07-10,2026-10-10,0,Gym@1013,Endomorph: Metabolic Shred & Furnace',
      'GC-M-1014,Danish Qureshi,+923125556677,danish@example.com,Annual VIP Access,2026-02-01,2027-02-01,5000,Gym@1014,Mesomorph: Athletic Power & V-Taper',
    ];

    return '${headers.join(',')}\n${sampleRows.join('\n')}';
  }
}
