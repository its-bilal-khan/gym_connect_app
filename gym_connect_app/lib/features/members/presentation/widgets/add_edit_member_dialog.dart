import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/gym_member.dart';

class AddEditMemberDialog extends StatefulWidget {
  final String tenantId;
  final GymMember? initialMember;
  final Function(GymMember member) onSave;

  const AddEditMemberDialog({
    super.key,
    required this.tenantId,
    this.initialMember,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String tenantId,
    GymMember? initialMember,
    required Function(GymMember member) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AddEditMemberDialog(
        tenantId: tenantId,
        initialMember: initialMember,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddEditMemberDialog> createState() => _AddEditMemberDialogState();
}

class _AddEditMemberDialogState extends State<AddEditMemberDialog> {
  late TextEditingController _codeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _duesCtrl;
  late TextEditingController _passCtrl;

  late String _selectedPlan;
  late String _selectedProtocol;
  late MemberAccountStatus _selectedStatus;
  late DateTime _expiryDate;

  final List<String> _plans = [
    'Annual VIP Access',
    'Monthly Fitness Plan',
    'Quarterly Shred Protocol',
    'Semi-Annual Pro',
    'Standard Gym Access'
  ];

  final List<String> _protocols = [
    'Mesomorph: Athletic Power & V-Taper',
    'Ectomorph: Lean Bulk Mass',
    'Endomorph: Metabolic Shred & Furnace',
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.initialMember;
    final randCode = 'GC-M-${1000 + Random().nextInt(8999)}';

    _codeCtrl = TextEditingController(text: m?.memberCode ?? randCode);
    _nameCtrl = TextEditingController(text: m?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: m?.phone ?? '+923');
    _emailCtrl = TextEditingController(text: m?.email ?? '');
    _duesCtrl = TextEditingController(text: m?.duesAmount.toStringAsFixed(0) ?? '0');
    _passCtrl = TextEditingController(text: m?.tempPassword ?? 'Gym@2026');

    _selectedPlan = m != null && _plans.contains(m.planName) ? m.planName : _plans.first;
    _selectedProtocol = m != null && _protocols.contains(m.assignedProtocol) ? m.assignedProtocol : _protocols.first;
    _selectedStatus = m?.status ?? MemberAccountStatus.active;
    _expiryDate = m?.expiryDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _duesCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter member full name.')),
      );
      return;
    }

    final code = _codeCtrl.text.trim().isEmpty ? 'GC-M-${1000 + Random().nextInt(8999)}' : _codeCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim().isEmpty ? '${code.toLowerCase()}@gymconnect.internal' : _emailCtrl.text.trim();
    final dues = double.tryParse(_duesCtrl.text.trim()) ?? 0.0;
    final pass = _passCtrl.text.trim().isEmpty ? 'Gym@2026' : _passCtrl.text.trim();

    final member = (widget.initialMember ?? GymMember(
      id: 'm-${DateTime.now().millisecondsSinceEpoch}',
      tenantId: widget.tenantId,
      memberCode: code,
      fullName: name,
      phone: phone,
      email: email,
      joinDate: DateTime.now(),
      expiryDate: _expiryDate,
    )).copyWith(
      memberCode: code,
      fullName: name,
      phone: phone,
      email: email,
      planName: _selectedPlan,
      assignedProtocol: _selectedProtocol,
      status: _selectedStatus,
      expiryDate: _expiryDate,
      duesAmount: dues,
      duesStatus: dues > 0 ? MemberDuesStatus.unpaid : MemberDuesStatus.paid,
      tempPassword: pass,
    );

    widget.onSave(member);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isEdit = widget.initialMember != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: Icon(isEdit ? Icons.edit_rounded : Icons.person_add_rounded, color: accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'EDIT GYM MEMBER' : 'REGISTER NEW MEMBER',
                        style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 24),

              // Form Scrollable
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInput('Member Code', _codeCtrl, hint: 'GC-M-1011'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInput('Full Name *', _nameCtrl, hint: 'e.g. Bilal Ahmed'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInput('Phone Number', _phoneCtrl, hint: '+923001234567'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInput('Email Address', _emailCtrl, hint: 'member@example.com'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Membership Plan',
                              value: _selectedPlan,
                              items: _plans,
                              onChanged: (v) => setState(() => _selectedPlan = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInput('Pending Dues (PKR)', _duesCtrl, hint: '0'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Assigned Workout Protocol',
                              value: _selectedProtocol,
                              items: _protocols,
                              onChanged: (v) => setState(() => _selectedProtocol = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInput('Initial Password', _passCtrl, hint: 'Gym@2026'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Membership Expiry Date', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _expiryDate,
                                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                                    );
                                    if (picked != null) setState(() => _expiryDate = picked);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2, '0')}-${_expiryDate.day.toString().padLeft(2, '0')}', style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
                                        Icon(Icons.calendar_today_rounded, size: 16, color: accent),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(color: AppColors.border, height: 24),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _onSavePressed,
                    child: Text(isEdit ? 'Save Changes' : 'Register Member', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, {required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white24),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
