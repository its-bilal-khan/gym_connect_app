import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/features/payments/presentation/providers/payments_providers.dart';

/// Mini live preview matching the exact signature layout of PendingPaymentCard in GymOwnerPaymentApprovalsScreen.
class MiniPaymentApprovalsPreview extends ConsumerWidget {
  final String tenantId;

  const MiniPaymentApprovalsPreview({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final paymentsAsync = ref.watch(pendingPaymentsProvider(tenantId));

    return Container(
      color: const Color(0xFF0F0F13),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: paymentsAsync.maybeWhen(
        data: (payments) {
          final pendingList = payments.where((p) => p.isPending).toList();
          final payment = pendingList.isNotEmpty ? pendingList.first : null;
          final pendingCount = pendingList.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Payer Name + Bank Method Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.amber.withValues(alpha: 0.2),
                        child: const Icon(Icons.receipt_long_rounded, size: 12, color: Colors.amber),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        payment != null ? payment.userFullName.toUpperCase() : 'HAMZA ALI',
                        style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      payment != null ? payment.paymentMethod.toUpperCase() : 'MEEZAN BANK IBFT',
                      style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Middle: Amount & Slip Attachment
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        payment != null ? 'TRANSFER: PKR ${payment.amount.toStringAsFixed(0)}' : 'TRANSFER: PKR 4,500',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.oswald(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file_rounded, size: 9, color: Colors.white70),
                          const SizedBox(width: 2),
                          Text('SLIP #9921', style: GoogleFonts.inter(fontSize: 7.5, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Bottom: The Two Iconic Approval Action Buttons
              Expanded(
                child: Row(
                  children: [
                    // Reject Button
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                        ),
                        child: Center(
                          child: Text(
                            'REJECT',
                            style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Approve Button
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            'APPROVE & ACTIVATE ($pendingCount)',
                            style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        orElse: () => Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2)),
      ),
    );
  }
}
