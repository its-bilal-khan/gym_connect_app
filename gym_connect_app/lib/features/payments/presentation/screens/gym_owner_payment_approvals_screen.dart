import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/payment_submission.dart';
import '../providers/payments_providers.dart';
import '../widgets/pending_payment_card.dart';

class GymOwnerPaymentApprovalsScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const GymOwnerPaymentApprovalsScreen({
    super.key,
    required this.tenantId,
  });

  static Future<void> open(BuildContext context, {required String tenantId}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GymOwnerPaymentApprovalsScreen(tenantId: tenantId),
      ),
    );
  }

  @override
  ConsumerState<GymOwnerPaymentApprovalsScreen> createState() => _GymOwnerPaymentApprovalsScreenState();
}

class _GymOwnerPaymentApprovalsScreenState extends ConsumerState<GymOwnerPaymentApprovalsScreen> {
  String? _processingPaymentId;

  Future<void> _handleApprove(PaymentSubmission payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('APPROVE PAYMENT?', style: GoogleFonts.oswald(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Approve PKR ${payment.amount.toInt()} for ${payment.userFullName}? This will immediately activate their membership.', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingPaymentId = payment.id);
    final notifier = ref.read(paymentActionNotifierProvider.notifier);
    final success = await notifier.approvePayment(
      paymentId: payment.id,
      targetUserId: payment.userId,
      tenantId: widget.tenantId,
      amount: payment.amount,
    );

    if (!mounted) return;
    setState(() => _processingPaymentId = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Payment approved & subscription activated!' : 'Failed to approve payment', style: GoogleFonts.inter(fontSize: 12)),
        backgroundColor: success ? Colors.green.shade800 : Colors.redAccent,
      ),
    );
  }

  Future<void> _handleReject(PaymentSubmission payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('REJECT PAYMENT?', style: GoogleFonts.oswald(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Mark this submission of PKR ${payment.amount.toInt()} from ${payment.userFullName} as rejected?', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject Payment'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingPaymentId = payment.id);
    final notifier = ref.read(paymentActionNotifierProvider.notifier);
    final success = await notifier.rejectPayment(
      paymentId: payment.id,
      targetUserId: payment.userId,
      tenantId: widget.tenantId,
    );

    if (!mounted) return;
    setState(() => _processingPaymentId = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Payment rejected.' : 'Failed to reject payment', style: GoogleFonts.inter(fontSize: 12)),
        backgroundColor: success ? Colors.grey.shade800 : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingPaymentsProvider(widget.tenantId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('PAYMENT PROOFS & APPROVALS', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(pendingPaymentsProvider(widget.tenantId)),
        child: pendingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(child: Text('Error loading payments: $err', style: GoogleFonts.inter(color: Colors.white))),
          data: (payments) {
            if (payments.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text('ALL CAUGHT UP!', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text('No pending manual payments waiting for approval.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: payments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final payment = payments[index];
                return PendingPaymentCard(
                  payment: payment,
                  isProcessing: _processingPaymentId == payment.id,
                  onApprove: () => _handleApprove(payment),
                  onReject: () => _handleReject(payment),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
