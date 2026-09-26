import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/secure_storage_service.dart';

class ProtocolStudioGridViewNotifier extends Notifier<bool> {
  @override
  bool build() {
    _init();
    return false;
  }

  Future<void> _init() async {
    final storage = ref.read(secureStorageProvider);
    final saved = await storage.getProtocolStudioGridView();
    state = saved;
  }

  Future<void> setGridView(bool isGrid) async {
    state = isGrid;
    final storage = ref.read(secureStorageProvider);
    await storage.saveProtocolStudioGridView(isGrid);
  }
}

final protocolStudioGridViewProvider =
    NotifierProvider<ProtocolStudioGridViewNotifier, bool>(
  ProtocolStudioGridViewNotifier.new,
);
