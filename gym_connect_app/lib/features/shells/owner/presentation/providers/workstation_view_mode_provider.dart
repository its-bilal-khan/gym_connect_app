import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/secure_storage_service.dart';

enum WorkstationViewMode {
  enterprise, // Option 3: Modern Enterprise SaaS Cards (Ultra-fast, 60fps)
  bentoPreview, // Option 1: Full Bento Grid with live scaled mini-previews
}

final workstationViewModeProvider =
    NotifierProvider<WorkstationViewModeNotifier, WorkstationViewMode>(
  WorkstationViewModeNotifier.new,
);

class WorkstationViewModeNotifier extends Notifier<WorkstationViewMode> {
  @override
  WorkstationViewMode build() {
    _loadPersistedMode();
    return WorkstationViewMode.enterprise;
  }

  Future<void> _loadPersistedMode() async {
    final storage = ref.read(secureStorageProvider);
    try {
      final saved = await storage.getWorkstationViewMode();
      if (saved != null) {
        if (saved == 'bentoPreview') {
          state = WorkstationViewMode.bentoPreview;
        } else if (saved == 'enterprise') {
          state = WorkstationViewMode.enterprise;
        }
      }
    } catch (_) {}
  }

  Future<void> setViewMode(WorkstationViewMode mode) async {
    state = mode;
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.saveWorkstationViewMode(mode.name);
    } catch (_) {}
  }
}
