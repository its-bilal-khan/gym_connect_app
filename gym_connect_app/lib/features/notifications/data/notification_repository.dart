import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../membership/data/membership_repository.dart';
import '../../store/data/store_repository.dart';

enum NotificationType { paymentDue, storeProduct, announcement }

class GymNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionPayload;

  const GymNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionPayload,
  });

  GymNotification copyWith({bool? isRead}) {
    return GymNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      actionPayload: actionPayload,
    );
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (e) {
    debugPrint('NotificationRepository: Supabase client unavailable: $e');
  }
  return NotificationRepository(client, ref);
});

final gymNotificationsProvider = NotifierProvider<GymNotificationsNotifier, List<GymNotification>>(GymNotificationsNotifier.new);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(gymNotificationsProvider);
  return list.where((n) => !n.isRead).length;
});

class GymNotificationsNotifier extends Notifier<List<GymNotification>> {
  @override
  List<GymNotification> build() {
    Future.microtask(() => loadNotifications());
    return const [];
  }

  Future<void> loadNotifications() async {
    final repo = ref.read(notificationRepositoryProvider);
    final list = await repo.fetchNotifications();
    state = list;
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }
}

class NotificationRepository {
  final SupabaseClient? supabase;
  final Ref _ref;

  const NotificationRepository(this.supabase, this._ref);

  Future<List<GymNotification>> fetchNotifications() async {
    final list = <GymNotification>[];

    // 1. Check pending invoice dues
    try {
      final invoice = await _ref.read(membershipRepositoryProvider).fetchPendingInvoice();
      if (invoice != null && invoice.dueAmount > 0) {
        list.add(GymNotification(
          id: 'notif-due-${invoice.id}',
          title: 'Membership Dues Due Tomorrow',
          message: 'Your monthly renewal of PKR ${invoice.dueAmount.toInt()} is pending. Pay now to prevent gate lockout.',
          type: NotificationType.paymentDue,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          actionPayload: invoice.id,
        ));
      }
    } catch (e) {
      debugPrint('NotificationRepository: check dues error: $e');
    }

    // 2. Check store products
    try {
      final products = await _ref.read(storeProductsProvider.future);
      if (products.isNotEmpty) {
        final top = products.first;
        list.add(GymNotification(
          id: 'notif-prod-${top.id}',
          title: '🔥 New Arrival at Front Desk',
          message: '${top.name} is now in stock for PKR ${top.price.toInt()}. Tap to view details and reserve.',
          type: NotificationType.storeProduct,
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          actionPayload: top.id,
        ));
      }
    } catch (e) {
      debugPrint('NotificationRepository: store products error: $e');
    }

    // 3. Facility Announcement
    list.add(GymNotification(
      id: 'notif-gym-hours',
      title: 'Extended Evening Hours',
      message: 'Peak hours extended until 11:30 PM this weekend with certified trainers on floor.',
      type: NotificationType.announcement,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ));

    return list;
  }
}
