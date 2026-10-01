import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/moderation_queue_provider.dart';
import 'flagged_fraud_grid_view.dart';
import 'flagged_fraud_list_view.dart';

class FlaggedFraudModerationDialog extends ConsumerStatefulWidget {
  final String tenantId;
  final String reviewerId;

  const FlaggedFraudModerationDialog({
    super.key,
    required this.tenantId,
    required this.reviewerId,
  });

  static Future<void> show(BuildContext context, {required String tenantId, required String reviewerId}) => showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 680),
            child: FlaggedFraudModerationDialog(tenantId: tenantId, reviewerId: reviewerId),
          ),
        ),
      );

  @override
  ConsumerState<FlaggedFraudModerationDialog> createState() => _FlaggedFraudModerationDialogState();
}

class _FlaggedFraudModerationDialogState extends ConsumerState<FlaggedFraudModerationDialog> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(moderationQueueProvider.notifier).loadItems(widget.tenantId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(moderationQueueProvider);
    final notifier = ref.read(moderationQueueProvider.notifier);
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: accent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FLAGGED FRAUD MODERATION QUEUE', style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Review suspicious diet logs or manual step overrides', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              // Rule 5 Dual-View Toggle Switch
              Container(
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.view_list_rounded, size: 18, color: state.isListView ? accent : AppColors.textSecondary),
                      onPressed: () => notifier.setViewMode(ModerationViewMode.list),
                      tooltip: 'List View',
                    ),
                    IconButton(
                      icon: Icon(Icons.grid_view_rounded, size: 18, color: !state.isListView ? accent : AppColors.textSecondary),
                      onPressed: () => notifier.setViewMode(ModerationViewMode.grid),
                      tooltip: 'Grid View',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: state.isListView
                        ? FlaggedFraudListView(
                            items: state.items,
                            reviewerId: widget.reviewerId,
                            onApprove: (id) => notifier.approveItem(queueId: id, reviewerId: widget.reviewerId),
                            onClawback: (id) => notifier.clawbackPoints(queueId: id, reviewerId: widget.reviewerId, auditNotes: 'Clawback issued by gym owner'),
                          )
                        : FlaggedFraudGridView(
                            items: state.items,
                            reviewerId: widget.reviewerId,
                            onApprove: (id) => notifier.approveItem(queueId: id, reviewerId: widget.reviewerId),
                            onClawback: (id) => notifier.clawbackPoints(queueId: id, reviewerId: widget.reviewerId, auditNotes: 'Clawback issued by gym owner'),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
