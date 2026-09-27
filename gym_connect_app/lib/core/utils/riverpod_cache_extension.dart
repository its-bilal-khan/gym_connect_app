import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension CacheForExtension on Ref {
  /// Keeps the provider alive for [duration] after all listeners have been removed.
  /// If a new listener arrives before the timer expires, the timer is cancelled
  /// and the cached value is reused without refetching.
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;
    onDispose(() => timer?.cancel());
    onCancel(() => timer = Timer(duration, () => link.close()));
    onResume(() => timer?.cancel());
  }
}
