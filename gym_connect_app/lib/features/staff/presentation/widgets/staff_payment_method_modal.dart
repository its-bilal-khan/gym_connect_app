import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class StaffPaymentMethodModal extends StatefulWidget {
  final double totalAmount;
  final String paymentMethod;
  final ValueChanged<String> onConfirm;

  const StaffPaymentMethodModal({
    super.key,
    required this.totalAmount,
    required this.paymentMethod,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required double totalAmount,
    required String paymentMethod,
    required ValueChanged<String> onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StaffPaymentMethodModal(
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<StaffPaymentMethodModal> createState() => _StaffPaymentMethodModalState();
}

class _StaffPaymentMethodModalState extends State<StaffPaymentMethodModal> {
  final _tenderedController = TextEditingController();
  final _mobileController = TextEditingController(text: '03001234567');
  double _change = 0.0;

  @override
  void initState() {
    super.initState();
    _tenderedController.text = widget.totalAmount.toInt().toString();
  }

  @override
  void dispose() {
    _tenderedController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _onTenderedChanged(String val) {
    final tendered = double.tryParse(val) ?? 0.0;
    setState(() => _change = (tendered - widget.totalAmount).clamp(0.0, 999999.0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    final method = widget.paymentMethod.replaceAll('_', ' ');

    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$method TERMINAL', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 10),
          _buildMethodBody(accent),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onConfirm(widget.paymentMethod == 'Khata_Credit' ? 'Hamza Tariq (VIP #002)' : 'Walk-In Customer');
            },
            style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('AUTHORIZE & COMPLETE SALE (PKR ${widget.totalAmount.toInt()})', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodBody(Color accent) {
    if (widget.paymentMethod == 'Cash') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CASH TENDERED (PKR)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _tenderedController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            ),
            onChanged: _onTenderedChanged,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CHANGE TO RETURN:', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                Text('PKR ${_change.toInt()}', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              ],
            ),
          ),
        ],
      );
    } else if (widget.paymentMethod == 'Khata_Credit') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VERIFIED VIP MEMBER KHATA', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
            const SizedBox(height: 4),
            Text('Hamza Tariq (Member #002)', style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Available Credit: PKR 21,500 • New Balance: PKR ${(21500 - widget.totalAmount).toInt()}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      );
    } else if (widget.paymentMethod == 'JazzCash' || widget.paymentMethod == 'EasyPaisa') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 40, color: Colors.cyanAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DYNAMIC MERCHANT QR ACTIVE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Ask customer to scan QR with their ${widget.paymentMethod} App', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3))),
        child: Row(
          children: [
            const Icon(Icons.credit_card_rounded, color: Colors.blueAccent, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('POS TERMINAL READY (PAX A920)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  Text('Tap, swipe, or insert customer Visa / Mastercard on terminal.', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
