import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_connect_app/core/services/secure_storage_service.dart';
import 'package:gym_connect_app/features/shells/owner/presentation/providers/workstation_view_mode_provider.dart';

class FakeSecureStorageService extends SecureStorageService {
  final Map<String, String> _memory = {};

  @override
  Future<void> saveWorkstationViewMode(String mode) async {
    _memory['owner_workstation_view_mode'] = mode;
  }

  @override
  Future<String?> getWorkstationViewMode() async {
    return _memory['owner_workstation_view_mode'];
  }
}

void main() {
  group('Workstation View Mode Switching & Reload Persistence Tests', () {
    test('Default mode is enterprise, switches to bentoPreview, and persists to storage', () async {
      final fakeStorage = FakeSecureStorageService();

      final rootContainer = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(fakeStorage),
        ],
      );

      // 1. Verify default mode is enterprise
      expect(
        rootContainer.read(workstationViewModeProvider),
        equals(WorkstationViewMode.enterprise),
      );

      // 2. Switch to Bento Preview mode
      await rootContainer
          .read(workstationViewModeProvider.notifier)
          .setViewMode(WorkstationViewMode.bentoPreview);

      expect(
        rootContainer.read(workstationViewModeProvider),
        equals(WorkstationViewMode.bentoPreview),
      );

      // 3. Verify saved to storage
      final savedMode = await fakeStorage.getWorkstationViewMode();
      expect(savedMode, equals('bentoPreview'));

      // 4. Simulate page reload by creating a brand new ProviderContainer
      final reloadedContainer = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(fakeStorage),
        ],
      );

      // Trigger initialization
      reloadedContainer.read(workstationViewModeProvider);
      // Allow async load to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        reloadedContainer.read(workstationViewModeProvider),
        equals(WorkstationViewMode.bentoPreview),
      );

      // 5. Switch back to Enterprise mode
      await reloadedContainer
          .read(workstationViewModeProvider.notifier)
          .setViewMode(WorkstationViewMode.enterprise);

      expect(
        reloadedContainer.read(workstationViewModeProvider),
        equals(WorkstationViewMode.enterprise),
      );

      final reSavedMode = await fakeStorage.getWorkstationViewMode();
      expect(reSavedMode, equals('enterprise'));
    });
  });
}
