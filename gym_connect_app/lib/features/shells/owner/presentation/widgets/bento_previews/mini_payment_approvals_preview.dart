import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/payments/domain/models/payment_submission.dart';
import 'package:gym_connect_app/features/payments/presentation/providers/payments_providers.dart';

/// 1:1 exact scaled live preview of GymOwnerPaymentApprovalsScreen matching user screenshot.
class MiniPaymentApprovalsPreview extends ConsumerWidget {
  final String tenantId;

  const MiniPaymentApprovalsPreview({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final paymentsAsync = ref.watch(pendingPaymentsProvider(tenantId));
    final viewMode = ref.watch(paymentViewModeProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Container(
          width: 1024,
          height: 492,
          color: const Color(0xFF09090B),
          child: paymentsAsync.maybeWhen(
            data: (payments) => _buildLiveScreen(payments, viewMode, accent),
            orElse: () => _buildLiveScreen([], viewMode, accent),
          ),
        );

        return FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: SizedBox(
            width: 1024,
            height: 492,
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildLiveScreen(
    List<PaymentSubmission> payments,
    PaymentViewMode viewMode,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top AppBar Row
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: AppColors.surface,
          child: Row(
            children: [
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                'PAYMENT PROOFS & APPROVALS',
                style: GoogleFonts.oswald(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${payments.length} TRANSFERS PENDING AUDIT',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Subheader Filter & View Mode Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Row 1: Search Input + Dual-View Switch
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Search transfers by member name, email, phone, or method...',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewBadge(
                          icon: Icons.grid_view_rounded,
                          label: 'Grid View',
                          isSelected: viewMode == PaymentViewMode.grid,
                          accent: accent,
                        ),
                        const SizedBox(width: 2),
                        _buildViewBadge(
                          icon: Icons.view_list_rounded,
                          label: 'List View',
                          isSelected: viewMode == PaymentViewMode.list,
                          accent: accent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Payment Method Filter Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabChip('ALL', payments.length, true, accent),
                  const SizedBox(width: 6),
                  _buildTabChip(
                    'EASYPAISA',
                    payments
                        .where((p) => p.paymentMethod
                            .toLowerCase()
                            .contains('easypaisa'))
                        .length,
                    false,
                    accent,
                  ),
                  const SizedBox(width: 6),
                  _buildTabChip(
                    'JAZZCASH',
                    payments
                        .where((p) => p.paymentMethod
                            .toLowerCase()
                            .contains('jazzcash'))
                        .length,
                    false,
                    accent,
                  ),
                  const SizedBox(width: 6),
                  _buildTabChip(
                    'BANK IBFT',
                    payments
                        .where((p) =>
                            p.paymentMethod.toLowerCase().contains('bank') ||
                            p.paymentMethod.toLowerCase().contains('ibft') ||
                            p.paymentMethod.toLowerCase().contains('meezan') ||
                            p.paymentMethod.toLowerCase().contains('transfer'))
                        .length,
                    false,
                    accent,
                  ),
                  const SizedBox(width: 6),
                  _buildTabChip(
                    'SADAPAY',
                    payments
                        .where((p) =>
                            p.paymentMethod.toLowerCase().contains('sada') ||
                            p.paymentMethod.toLowerCase().contains('naya'))
                        .length,
                    false,
                    accent,
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3. Payments Grid / List Body
        Expanded(
          child: Container(
            color: const Color(0xFF09090B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: viewMode == PaymentViewMode.list
                ? _buildListView(payments, accent)
                : _buildGridView(payments, accent),
          ),
        ),
      ],
    );
  }

  Widget _buildViewBadge({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? accent.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              isSelected ? accent.withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: isSelected ? accent : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? accent : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(
      String label, int count, bool isSelected, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            isSelected ? accent.withValues(alpha: 0.16) : AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? accent : AppColors.border,
          width: isSelected ? 1.3 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? accent : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<PaymentSubmission> payments, Color accent) {
    final displayList = payments.take(6).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int col = 0; col < 3; col++) ...[
          Expanded(
            child: Column(
              children: [
                if (col < displayList.length)
                  Expanded(
                    child: _buildPaymentMiniCard(displayList[col], accent),
                  ),
                const SizedBox(height: 10),
                if (col + 3 < displayList.length)
                  Expanded(
                    child: _buildPaymentMiniCard(displayList[col + 3], accent),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
          if (col < 2) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildPaymentMiniCard(PaymentSubmission payment, Color accent) {
    final hasReceipt = payment.receiptImageUrl != null &&
        payment.receiptImageUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Name + Method Pill
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      payment.userFullName.toUpperCase(),
                      style: GoogleFonts.oswald(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      payment.paymentMethod.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                payment.userEmail.isNotEmpty
                    ? payment.userEmail
                    : 'user@gym.com',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 8,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // Middle: Receipt Proof Attachment
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 24,
                    height: 24,
                    color: Colors.white12,
                    child: hasReceipt
                        ? Image.network(
                            payment.receiptImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.receipt_long,
                                    size: 14, color: Colors.white38),
                          )
                        : const Icon(Icons.receipt_long,
                            size: 14, color: Colors.white38),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasReceipt ? 'Slip Screenshot Attached' : 'Manual Transfer',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Icon(Icons.zoom_in_rounded, size: 12, color: accent),
              ],
            ),
          ),

          // Footer: Amount + Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PKR ${payment.amount.toStringAsFixed(0)}',
                style: GoogleFonts.oswald(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            const Color(0xFFEF4444).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'REJECT',
                      style: GoogleFonts.inter(
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'APPROVE',
                      style: GoogleFonts.inter(
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<PaymentSubmission> payments, Color accent) {
    final displayList = payments.take(4).toList();

    return Column(
      children: [
        for (final payment in displayList) ...[
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.receipt_long_rounded,
                        size: 16, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          payment.userFullName.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${payment.userEmail} • ${payment.paymentMethod}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'PKR ${payment.amount.toStringAsFixed(0)}',
                    style: GoogleFonts.oswald(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'APPROVE',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
