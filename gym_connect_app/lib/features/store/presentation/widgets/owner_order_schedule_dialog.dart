import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/store_repository.dart';

class OwnerOrderScheduleDialog extends StatefulWidget {
  final StoreOrder order;
  final Function(String status, String readyDate, String readyTime) onSchedule;

  const OwnerOrderScheduleDialog({
    super.key,
    required this.order,
    required this.onSchedule,
  });

  static Future<void> show(
    BuildContext context, {
    required StoreOrder order,
    required Function(String status, String readyDate, String readyTime) onSchedule,
  }) {
    return showDialog(
      context: context,
      builder: (_) => OwnerOrderScheduleDialog(order: order, onSchedule: onSchedule),
    );
  }

  @override
  State<OwnerOrderScheduleDialog> createState() => _OwnerOrderScheduleDialogState();
}

class _OwnerOrderScheduleDialogState extends State<OwnerOrderScheduleDialog> {
  late DateTime _selectedDate;
  late TextEditingController _timeController;
  final String _selectedStatus = 'ready_for_pickup';

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _timeController = TextEditingController(text: 'Today 5:00 PM - 8:00 PM');
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'SCHEDULE ORDER READINESS',
        style: GoogleFonts.oswald(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set date and time window when ${widget.order.customerName} can ${widget.order.isDelivery ? "receive delivery" : "collect from gym"}:',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
              label: Text('DATE: $dateStr', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border), padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeController,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Estimated Time Window',
                labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                hintText: 'e.g. 4:00 PM - 7:00 PM',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _quickTimeChip('Ready in 30 Mins'),
                const SizedBox(width: 6),
                _quickTimeChip('Tomorrow 5 PM'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
          onPressed: () {
            Navigator.pop(context);
            widget.onSchedule(_selectedStatus, dateStr, _timeController.text.trim());
          },
          child: const Text('Save & Notify Customer'),
        ),
      ],
    );
  }

  Widget _quickTimeChip(String text) {
    return InkWell(
      onTap: () => setState(() => _timeController.text = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
        child: Text(text, style: GoogleFonts.inter(fontSize: 10, color: AppColors.primary)),
      ),
    );
  }
}
