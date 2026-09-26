import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/providers/auth_notifier.dart';
import '../../auth/presentation/providers/auth_state.dart';
import '../../auth/domain/models/user_role.dart';
import '../../membership/data/membership_repository.dart';
import '../../payments/data/payments_repository.dart';
import '../../store/data/store_repository.dart';

enum NotificationType { paymentDue, storeProduct, announcement, storeOrder, gatePass }

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

  factory GymNotification.fromJson(Map<String, dynamic> json) {
    NotificationType parseType(String? t) {
      switch (t) {
        case 'paymentDue':
          return NotificationType.paymentDue;
        case 'storeOrder':
          return NotificationType.storeOrder;
        case 'storeProduct':
          return NotificationType.storeProduct;
        case 'gatePass':
          return NotificationType.gatePass;
        default:
          return NotificationType.announcement;
      }
    }

    return GymNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: parseType(json['type']?.toString()),
      timestamp: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      actionPayload: json['action_payload']?.toString(),
    );
  }

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

class LiveNotificationToastNotifier extends Notifier<GymNotification?> {
  @override
  GymNotification? build() => null;

  void show(GymNotification notification) {
    state = notification;
  }
}

/// Holds only live/active notifications triggered during the active user session
/// so historical background fetches do NOT pop up unwanted SnackBars.
final liveNotificationToastProvider =
    NotifierProvider<LiveNotificationToastNotifier, GymNotification?>(LiveNotificationToastNotifier.new);

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
    final fetched = await repo.fetchNotifications();
    final fetchedIds = fetched.map((n) => n.id).toSet();
    final retained = state.where((n) => !fetchedIds.contains(n.id)).toList();
    state = [...retained, ...fetched];
  }

  void pushNotification(GymNotification notification, {bool showToast = true}) {
    state = [
      notification,
      ...state.where((n) => n.id != notification.id),
    ];
    if (showToast) {
      ref.read(liveNotificationToastProvider.notifier).show(notification);
    }
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
    ref.read(notificationRepositoryProvider).markAsReadInDb(id);
  }

  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
    ref.read(notificationRepositoryProvider).markAllAsReadInDb();
  }
}

class NotificationRepository {
  final SupabaseClient? supabase;
  final Ref _ref;

  const NotificationRepository(this.supabase, this._ref);

  /// Fetches ONLY real, authentic notifications from live Supabase tables.
  /// Zero fake, dummy, or hardcoded mock notifications.
  Future<List<GymNotification>> fetchNotifications() async {
    final list = <GymNotification>[];

    final authState = _ref.read(authNotifierProvider);
    final activeRole = (authState is AuthAuthenticated) ? authState.activeRole : UserRole.member;
    final profileUserId = (authState is AuthAuthenticated) ? authState.profile.id : '';
    final tenantId = (authState is AuthAuthenticated) ? (authState.profile.tenantId ?? '') : '';
    final effectiveUserId = (supabase?.auth.currentUser?.id.isNotEmpty == true)
        ? supabase!.auth.currentUser!.id
        : profileUserId;

    // 1. Fetch real notifications from Supabase PostgreSQL table
    if (supabase != null && effectiveUserId.isNotEmpty) {
      try {
        var query = supabase!.from('notifications').select();
        if (tenantId.isNotEmpty) {
          query = query.or('user_id.eq.$effectiveUserId,and(user_id.is.null,tenant_id.eq.$tenantId)');
        } else {
          query = query.eq('user_id', effectiveUserId);
        }
        final res = await query.order('created_at', ascending: false).limit(20);
        for (final row in (res as List)) {
          list.add(GymNotification.fromJson(row as Map<String, dynamic>));
        }
      } catch (e) {
        debugPrint('NotificationRepository: database notifications fetch error: $e');
      }
    }

    // 2. Check pending invoice dues ONLY if a real unpaid invoice exists in Supabase
    if (activeRole == UserRole.member) {
      try {
        final invoice = await _ref.read(membershipRepositoryProvider).fetchPendingInvoice();
        if (invoice != null && invoice.dueAmount > 0) {
          list.add(GymNotification(
            id: 'notif-due-${invoice.id}',
            title: 'Membership Dues Pending',
            message: 'Your monthly renewal of PKR ${invoice.dueAmount.toInt()} is pending. Pay now to prevent gate lockout.',
            type: NotificationType.paymentDue,
            timestamp: invoice.createdAt ?? DateTime.now(),
            actionPayload: invoice.id,
          ));
        }
      } catch (e) {
        debugPrint('NotificationRepository: check dues error: $e');
      }
    }

    // 3. For Gym Owner & Staff: Check real pending member payment receipts waiting for review
    if (activeRole == UserRole.owner || activeRole == UserRole.staff) {
      try {
        if (tenantId.isNotEmpty) {
          final pendingProofs = await _ref.read(paymentsRepositoryProvider).fetchPendingPayments(tenantId);
          if (pendingProofs.isNotEmpty) {
            list.add(GymNotification(
              id: 'notif-pending-receipts-${pendingProofs.length}',
              title: 'Pending Member Payment Slips',
              message: '${pendingProofs.length} manual transfer receipt(s) waiting for verification in your Executive Portal.',
              type: NotificationType.announcement,
              timestamp: pendingProofs.first.createdAt,
            ));
          }
        }
      } catch (e) {
        debugPrint('NotificationRepository: check owner pending proofs error: $e');
      }
    }

    // 4. For Members: Check real store customer orders ready for pickup
    if (activeRole == UserRole.member && effectiveUserId.isNotEmpty) {
      try {
        final orders = await _ref.read(storeRepositoryProvider).fetchCustomerOrders(effectiveUserId);
        for (final o in orders.take(6)) {
          final shortId = o.id.length > 6 ? o.id.substring(0, 6).toUpperCase() : o.id.toUpperCase();
          if (o.orderStatus == 'ready_for_pickup') {
            list.add(GymNotification(
              id: 'notif-order-ready-${o.id}',
              title: '🛒 Order Ready for Pickup! (Code: ${o.pickupCode})',
              message: 'Your order #$shortId (${o.items.length} items • PKR ${o.totalAmount.toInt()}) is ready! Show Counter Pickup Code ${o.pickupCode} at the front desk.',
              type: NotificationType.storeOrder,
              timestamp: o.createdAt,
              actionPayload: o.id,
            ));
          }
        }
      } catch (e) {
        debugPrint('NotificationRepository: store orders check error: $e');
      }
    }

    // Sort real notifications chronologically (latest first)
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return list;
  }

  Future<void> markAsReadInDb(String id) async {
    if (supabase == null) return;
    try {
      // If it's a UUID, update PostgreSQL notifications table
      if (RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id)) {
        await supabase!.from('notifications').update({'is_read': true}).eq('id', id);
      }
    } catch (e) {
      debugPrint('NotificationRepository: markAsReadInDb error: $e');
    }
  }

  Future<void> markAllAsReadInDb() async {
    if (supabase == null) return;
    try {
      final user = supabase!.auth.currentUser;
      if (user != null) {
        await supabase!.from('notifications').update({'is_read': true}).eq('user_id', user.id);
      }
    } catch (e) {
      debugPrint('NotificationRepository: markAllAsReadInDb error: $e');
    }
  }
}
