import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import '../../domain/models/workstation_item.dart';
import '../providers/workstation_view_mode_provider.dart';
import '../providers/workstations_order_provider.dart';
import 'bento_workstation_card_builder.dart';
import 'enterprise_cards/enterprise_workstation_card_builder.dart';

class OwnerWorkstationsGrid extends ConsumerWidget {
  final UserProfile profile;
  final String tenantId;
  final int pendingPayments;
  final int pendingOrders;
  final int activeMembers;
  final int productsCount;

  const OwnerWorkstationsGrid({
    super.key,
    required this.profile,
    required this.tenantId,
    required this.pendingPayments,
    required this.pendingOrders,
    required this.activeMembers,
    required this.productsCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationsOrder = ref.watch(workstationsOrderProvider(tenantId));
    final viewMode = ref.watch(workstationViewModeProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: workstationsOrder.asMap().entries.map((entry) {
            final index = entry.key;
            final id = entry.value;

            return DragTarget<int>(
              onWillAcceptWithDetails: (details) => details.data != index,
              onAcceptWithDetails: (details) {
                ref
                    .read(workstationsOrderProvider(tenantId).notifier)
                    .reorder(details.data, index);
              },
              builder: (context, candidateData, rejectedData) {
                final isTargeted = candidateData.isNotEmpty;

                final regularCard = _buildCard(
                  id: id,
                  index: index,
                  viewMode: viewMode,
                  cardWidth: cardWidth,
                  context: context,
                  isFeedback: false,
                );

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: isTargeted
                        ? Border.all(color: accent, width: 2)
                        : null,
                    boxShadow: isTargeted
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Draggable<int>(
                    data: index,
                    dragAnchorStrategy: pointerDragAnchorStrategy,
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: cardWidth,
                        height: 205,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.45),
                                blurRadius: 28,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Opacity(
                            opacity: 0.95,
                            child: _buildCard(
                              id: id,
                              index: index,
                              viewMode: viewMode,
                              cardWidth: cardWidth,
                              context: context,
                              isFeedback: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: _buildPlaceholder(cardWidth, accent),
                    child: regularCard,
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCard({
    required WorkstationId id,
    required int index,
    required WorkstationViewMode viewMode,
    required double cardWidth,
    required BuildContext context,
    required bool isFeedback,
  }) {
    final accent = Theme.of(context).colorScheme.primary;
    final dragHandle = isFeedback ? null : _buildHandle(index, accent);

    if (viewMode == WorkstationViewMode.enterprise) {
      return buildEnterpriseCard(
        context: context,
        id: id,
        cardWidth: cardWidth,
        profile: profile,
        tenantId: tenantId,
        pendingPayments: pendingPayments,
        pendingOrders: pendingOrders,
        activeMembers: activeMembers,
        productsCount: productsCount,
        dragHandle: dragHandle,
        isFeedback: isFeedback,
      );
    }

    return buildBentoCard(
      context: context,
      id: id,
      cardWidth: cardWidth,
      profile: profile,
      tenantId: tenantId,
      pendingPayments: pendingPayments,
      pendingOrders: pendingOrders,
      dragHandle: dragHandle,
      isFeedback: isFeedback,
    );
  }

  Widget _buildHandle(int index, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.drag_indicator_rounded, color: accent, size: 14),
          const SizedBox(width: 3),
          Text(
            '#${index + 1}',
            style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.bold, color: accent),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(double cardWidth, Color accent) {
    return Container(
      width: cardWidth,
      height: 205,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz_rounded,
                color: accent.withValues(alpha: 0.8), size: 22),
            const SizedBox(width: 8),
            Text(
              'REPOSITIONING WORKSTATION...',
              style: GoogleFonts.oswald(
                fontSize: 13,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: accent.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
