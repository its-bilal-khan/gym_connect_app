import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/diet_proof_service.dart';
import 'daily_gamification_provider.dart';

class DietProofState {
  final DietLogType logType;
  final String? photoUrl;
  final int pointsAwarded;
  final bool isUploading;
  final String? error;

  const DietProofState({
    this.logType = DietLogType.none,
    this.photoUrl,
    this.pointsAwarded = 0,
    this.isUploading = false,
    this.error,
  });

  DietProofState copyWith({
    DietLogType? logType,
    String? photoUrl,
    int? pointsAwarded,
    bool? isUploading,
    String? error,
  }) {
    return DietProofState(
      logType: logType ?? this.logType,
      photoUrl: photoUrl ?? this.photoUrl,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      isUploading: isUploading ?? this.isUploading,
      error: error,
    );
  }
}

final dietProofProvider =
    NotifierProvider<DietProofNotifier, DietProofState>(DietProofNotifier.new);

class DietProofNotifier extends Notifier<DietProofState> {
  DietProofService get _service => ref.read(dietProofServiceProvider);

  @override
  DietProofState build() {
    Future.microtask(() => _loadFromExistingLog());
    return const DietProofState();
  }

  void _loadFromExistingLog() {
    final dailyState = ref.read(dailyGamificationProvider);
    final log = dailyState.todayLog;
    if (log != null && log.dietLoggedType != 'none') {
      final isPhoto = log.dietLoggedType == 'photo_proof';
      state = DietProofState(
        logType: isPhoto ? DietLogType.photoProof : DietLogType.selfCheck,
        photoUrl: log.dietProofUrl,
        pointsAwarded: isPhoto ? 15 : 2,
      );
    }
  }

  Future<bool> snapAndUploadPhoto({
    required String tenantId,
    required ImageSource source,
  }) async {
    state = state.copyWith(isUploading: true, error: null);
    try {
      final image = await _service.pickMealPhoto(source: source);
      if (image == null) {
        state = state.copyWith(isUploading: false);
        return false;
      }

      String? currentUid;
      try {
        currentUid = Supabase.instance.client.auth.currentUser?.id;
      } catch (_) {}
      final userId = currentUid ?? 'usr_guest';
      final uploadResult = await _service.uploadMealProof(
        userId: userId,
        filePath: image.path,
      );

      if (uploadResult.success) {
        state = DietProofState(
          logType: DietLogType.photoProof,
          photoUrl: uploadResult.proofUrl,
          pointsAwarded: 15,
          isUploading: false,
        );

        await ref.read(dailyGamificationProvider.notifier).submitDailyTasks(
              tenantId: tenantId,
              dietType: 'photo_proof',
              dietProofUrl: uploadResult.proofUrl,
            );
        return true;
      } else {
        state = state.copyWith(isUploading: false, error: uploadResult.errorMessage);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logSelfCheck({required String tenantId}) async {
    state = state.copyWith(isUploading: true, error: null);
    try {
      state = const DietProofState(
        logType: DietLogType.selfCheck,
        photoUrl: null,
        pointsAwarded: 2,
        isUploading: false,
      );

      await ref.read(dailyGamificationProvider.notifier).submitDailyTasks(
            tenantId: tenantId,
            dietType: 'self_check',
          );
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }
}
