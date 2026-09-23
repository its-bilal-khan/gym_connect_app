import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shells/member/presentation/widgets/pay_dues_sheet.dart';
import '../../../store/data/store_repository.dart';
import '../../../store/presentation/product_detail_screen.dart';
import '../../data/notification_repository.dart';

class GymNotificationsSheet extends ConsumerWidget {
  const GymNotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GymNotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(gymNotificationsProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NOTIFICATIONS & ALERTS', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              TextButton(
                onPressed: () => ref.read(gymNotificationsProvider.notifier).markAllAsRead(),
                child: Text('MARK ALL READ', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: accent)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (notifs.isEmpty)
            Expanded(child: Center(child: Text('No active notifications', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))))
          else
            Expanded(
              child: ListView.separated(
                itemCount: notifs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final n = notifs[i];
                  return _buildTile(context, ref, n, accent);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, WidgetRef ref, GymNotification n, Color accent) {
    final isUnread = !n.isRead;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnread ? accent.withValues(alpha: 0.08) : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUnread ? accent.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(n.type), size: 18, color: _colorFor(n.type, accent)),
              const SizedBox(width: 8),
              Expanded(child: Text(n.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
              if (isUnread) Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 6),
          Text(n.message, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 10),
          if (n.type == NotificationType.paymentDue)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                ref.read(gymNotificationsProvider.notifier).markAsRead(n.id);
                Navigator.pop(context);
                PayDuesSheet.show(context);
              },
              icon: const Icon(Icons.payment_rounded, size: 16),
              label: Text('PAY NOW & PREVENT LOCKOUT', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
            )
          else if (n.type == NotificationType.storeProduct)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: accent, side: BorderSide(color: accent), minimumSize: const Size.fromHeight(36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                ref.read(gymNotificationsProvider.notifier).markAsRead(n.id);
                Navigator.pop(context);
                final products = await ref.read(storeProductsProvider.future);
                final prod = products.where((p) => p.id == n.actionPayload).firstOrNull ?? products.firstOrNull;
                if (prod != null && context.mounted) {
                  ProductDetailScreen.open(context, product: prod, onAddToCart: (_) {});
                }
              },
              icon: const Icon(Icons.shopping_bag_rounded, size: 16),
              label: Text('VIEW PRODUCT DETAILS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.paymentDue: return Icons.warning_amber_rounded;
      case NotificationType.storeProduct: return Icons.local_fire_department_rounded;
      case NotificationType.announcement: return Icons.campaign_rounded;
    }
  }

  Color _colorFor(NotificationType type, Color accent) {
    switch (type) {
      case NotificationType.paymentDue: return Colors.amber;
      case NotificationType.storeProduct: return accent;
      case NotificationType.announcement: return Colors.cyanAccent;
    }
  }
}
