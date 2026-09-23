import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/providers/auth_notifier.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../../../membership/data/membership_repository.dart';
import '../../../../payments/presentation/providers/payments_providers.dart';
import '../../../../payments/presentation/screens/manual_checkout_screen.dart';
import '../gateways/external_payment_handoff_screen.dart';
import 'payment_due_summary_card.dart';

class PayDuesSheet extends ConsumerStatefulWidget {
  const PayDuesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PayDuesSheet(),
    );
  }

  @override
  ConsumerState<PayDuesSheet> createState() => _PayDuesSheetState();
}

class _PayDuesSheetState extends ConsumerState<PayDuesSheet> {
  String _selectedMethod = 'EasyPaisa';

  final List<Map<String, dynamic>> _methods = [
    {
      'id': 'manual',
      'label': 'Manual Screenshot (Proof of Payment)',
      'sub': 'Transfer via EasyPaisa/Bank & upload receipt',
      'icon': Icons.upload_file_rounded,
      'color': AppColors.primary,
      'badge': 'MANUAL PROOF',
    },
    {
      'id': 'JazzCash',
      'label': 'JazzCash Mobile Account',
      'sub': 'Opens official JazzCash App to approve',
      'icon': Icons.account_balance_wallet_rounded,
      'color': const Color(0xFFED1C24),
      'badge': 'WALLET APP',
    },
    {
      'id': 'EasyPaisa',
      'label': 'EasyPaisa Wallet',
      'sub': 'Opens official EasyPaisa App to approve',
      'icon': Icons.phone_android_rounded,
      'color': const Color(0xFF00A859),
      'badge': 'WALLET APP',
    },
    {
      'id': 'Card',
      'label': 'Debit / Credit Card (Visa/Mastercard)',
      'sub': 'Direct PayFast / 3D-Secure payment portal',
      'icon': Icons.credit_card_rounded,
      'color': Colors.blueAccent,
      'badge': 'GATEWAY',
    },
  ];

  void _triggerPayment(String method, PendingInvoiceInfo? invoice, double dueAmount, String tenantId) {
    setState(() => _selectedMethod = method);
    final invId = invoice?.id;
    final invNum = invoice?.invoiceNumber ?? 'INV-9821';

    if (method == 'manual') {
      Navigator.pop(context);
      ManualCheckoutScreen.open(
        context,
        tenantId: tenantId,
        amount: dueAmount,
        invoiceId: invId,
        invoiceNumber: invNum,
      );
      return;
    }

    ExternalPaymentHandoffScreen.open(
      context,
      method: method,
      amount: dueAmount,
      invoiceId: invId,
      invoiceNumber: invNum,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    final invoiceAsync = ref.watch(pendingInvoiceProvider);
    final invoice = invoiceAsync.asData?.value;
    final dueAmount = invoice?.dueAmount ?? 5000.0;
    final dueAmountStr = dueAmount.toInt().toString();

    final authState = ref.watch(authNotifierProvider);
    final tenantId = (authState is AuthAuthenticated) ? (authState.profile.tenantId ?? '') : '';
    final settingsAsync = ref.watch(tenantPaymentSettingsProvider(tenantId));
    final settings = settingsAsync.asData?.value;
    final isManual = settings?.isManualPaymentEnabled ?? false;
    final isPayfast = settings?.isPayfastEnabled ?? false;

    final activeMethods = _methods.where((m) {
      if (isManual && !isPayfast) {
        // Exclusively manual payment: hide other methods
        return m['id'] == 'manual';
      } else if (isPayfast && !isManual) {
        // Exclusively digital gateways
        return m['id'] != 'manual';
      }
      return true;
    }).toList();

    if (activeMethods.isNotEmpty && !activeMethods.any((m) => m['id'] == _selectedMethod)) {
      _selectedMethod = activeMethods.first['id'] as String;
    }

    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PAY DUES & RENEWAL', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            PaymentDueSummaryCard(invoice: invoice, dueAmountStr: dueAmountStr, accent: accent),
            const SizedBox(height: 16),
            Text('CHOOSE PAYMENT METHOD (OPENS APP / GATEWAY)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ...activeMethods.map((m) {
              final isSelected = _selectedMethod == m['id'];
              final color = m['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _triggerPayment(m['id'] as String, invoice, dueAmount, tenantId),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.12) : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), radius: 18, child: Icon(m['icon'] as IconData, color: color, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m['label'] as String, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textPrimary)),
                              Text(m['sub'] as String, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                          child: Text(m['badge'] as String, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => _triggerPayment(_selectedMethod, invoice, dueAmount, tenantId),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text('OPEN ${_selectedMethod.toUpperCase()} & PAY PKR $dueAmountStr', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }
}
