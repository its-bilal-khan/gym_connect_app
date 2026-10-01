import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/payment_submission.dart';
import '../providers/payments_providers.dart';
import '../widgets/owner_payment_grid_card.dart';
import '../widgets/owner_payment_list_row.dart';
import '../widgets/payment_view_mode_toggle.dart';

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
  ConsumerState<GymOwnerPaymentApprovalsScreen> createState() =>
      _GymOwnerPaymentApprovalsScreenState();
}

class _GymOwnerPaymentApprovalsScreenState
    extends ConsumerState<GymOwnerPaymentApprovalsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedMethod = 'ALL';
  String? _processingPaymentId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PaymentSubmission> _filterPayments(List<PaymentSubmission> payments) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return payments.where((payment) {
      final matchesQuery = query.isEmpty ||
          payment.userFullName.toLowerCase().contains(query) ||
          payment.userEmail.toLowerCase().contains(query) ||
          (payment.userPhone?.toLowerCase().contains(query) ?? false) ||
          payment.paymentMethod.toLowerCase().contains(query);

      bool matchesMethod = true;
      final meth = payment.paymentMethod.toLowerCase();
      if (_selectedMethod == 'EASYPAISA') {
        matchesMethod = meth.contains('easypaisa');
      } else if (_selectedMethod == 'JAZZCASH') {
        matchesMethod = meth.contains('jazzcash');
      } else if (_selectedMethod == 'BANK IBFT') {
        matchesMethod = meth.contains('bank') ||
            meth.contains('ibft') ||
            meth.contains('meezan') ||
            meth.contains('transfer');
      } else if (_selectedMethod == 'SADAPAY') {
        matchesMethod =
            meth.contains('sada') || meth.contains('naya');
      }

      return matchesQuery && matchesMethod;
    }).toList();
  }

  Future<void> _handleApprove(PaymentSubmission payment) async {
    final accent = Theme.of(context).colorScheme.primary;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'APPROVE PAYMENT?',
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        content: Text(
          'Approve PKR ${payment.amount.toInt()} for ${payment.userFullName}? This will immediately activate their membership subscription.',
          style: GoogleFonts.inter(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Approval',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
        content: Text(
          success
              ? 'Payment approved & subscription activated!'
              : 'Failed to approve payment',
          style: GoogleFonts.inter(fontSize: 12),
        ),
        backgroundColor: success ? Colors.green.shade800 : Colors.redAccent,
      ),
    );
  }

  Future<void> _handleReject(PaymentSubmission payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'REJECT PAYMENT?',
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        content: Text(
          'Mark submission of PKR ${payment.amount.toInt()} from ${payment.userFullName} as rejected?',
          style: GoogleFonts.inter(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject Payment',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
        content: Text(
          success ? 'Payment rejected.' : 'Failed to reject payment',
          style: GoogleFonts.inter(fontSize: 12),
        ),
        backgroundColor: success ? Colors.grey.shade800 : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final pendingAsync = ref.watch(pendingPaymentsProvider(widget.tenantId));
    final viewMode = ref.watch(paymentViewModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'PAYMENT PROOFS & APPROVALS',
              style: GoogleFonts.oswald(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            pendingAsync.maybeWhen(
              data: (payments) {
                final count = payments.length;
                if (count == 0) return const SizedBox.shrink();
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    '$count TRANSFERS PENDING AUDIT',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Subheader Filter & Dual-View Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Top row: Search input + View mode toggle
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText:
                                'Search transfers by member name, email, phone, or method...',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.textSecondary,
                              size: 19,
                            ),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.textSecondary,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Dual-View Segmented Toggle Switch (Rule 5)
                    PaymentViewModeToggle(
                      currentMode: viewMode,
                      onModeChanged: (mode) {
                        ref
                            .read(paymentViewModeProvider.notifier)
                            .setMode(mode);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bottom row: Payment Method Filter Chips
                pendingAsync.maybeWhen(
                  data: (payments) {
                    final allCount = payments.length;
                    final easypaisaCount = payments
                        .where((p) => p.paymentMethod
                            .toLowerCase()
                            .contains('easypaisa'))
                        .length;
                    final jazzcashCount = payments
                        .where((p) => p.paymentMethod
                            .toLowerCase()
                            .contains('jazzcash'))
                        .length;
                    final bankCount = payments
                        .where((p) =>
                            p.paymentMethod.toLowerCase().contains('bank') ||
                            p.paymentMethod.toLowerCase().contains('ibft') ||
                            p.paymentMethod.toLowerCase().contains('meezan') ||
                            p.paymentMethod.toLowerCase().contains('transfer'))
                        .length;
                    final sadapayCount = payments
                        .where((p) =>
                            p.paymentMethod.toLowerCase().contains('sada') ||
                            p.paymentMethod.toLowerCase().contains('naya'))
                        .length;

                    final tabs = [
                      {'label': 'ALL', 'count': allCount},
                      {'label': 'EASYPAISA', 'count': easypaisaCount},
                      {'label': 'JAZZCASH', 'count': jazzcashCount},
                      {'label': 'BANK IBFT', 'count': bankCount},
                      {'label': 'SADAPAY', 'count': sadapayCount},
                    ];

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: tabs.map((tab) {
                          final label = tab['label'] as String;
                          final count = tab['count'] as int;
                          final isSelected = _selectedMethod == label;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedMethod = label),
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? accent.withValues(alpha: 0.16)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? accent
                                        : AppColors.border,
                                    width: isSelected ? 1.4 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? accent
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? accent.withValues(alpha: 0.3)
                                            : Colors.white
                                                .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Main Payments Listing (Reactive Grid or List)
          Expanded(
            child: RefreshIndicator(
              color: accent,
              onRefresh: () async =>
                  ref.invalidate(pendingPaymentsProvider(widget.tenantId)),
              child: pendingAsync.when(
                loading: () =>
                    Center(child: CircularProgressIndicator(color: accent)),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load pending payments',
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$err',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                data: (payments) {
                  final filtered = _filterPayments(payments);

                  if (payments.isEmpty) {
                    return _buildEmptyState(accent);
                  }

                  if (filtered.isEmpty) {
                    return _buildEmptySearchResults(accent);
                  }

                  if (viewMode == PaymentViewMode.grid) {
                    return _buildGridView(filtered);
                  } else {
                    return _buildListView(filtered);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<PaymentSubmission> payments) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 3;
        if (width < 760) {
          crossAxisCount = 1;
        } else if (width < 1200) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 260,
          ),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return OwnerPaymentGridCard(
              payment: payment,
              isProcessing: _processingPaymentId == payment.id,
              onApprove: () => _handleApprove(payment),
              onReject: () => _handleReject(payment),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(List<PaymentSubmission> payments) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: payments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final payment = payments[index];
        return OwnerPaymentListRow(
          payment: payment,
          isProcessing: _processingPaymentId == payment.id,
          onApprove: () => _handleApprove(payment),
          onReject: () => _handleReject(payment),
        );
      },
    );
  }

  Widget _buildEmptyState(Color accent) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(Icons.check_circle_outline_rounded,
                    size: 54, color: accent),
              ),
              const SizedBox(height: 18),
              Text(
                'ALL CAUGHT UP!',
                style: GoogleFonts.oswald(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No pending manual payments waiting for approval.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySearchResults(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'NO MATCHING TRANSFERS FOUND',
            style: GoogleFonts.oswald(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search query or selecting a different payment method.',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _selectedMethod = 'ALL');
            },
            child: Text(
              'CLEAR FILTERS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
