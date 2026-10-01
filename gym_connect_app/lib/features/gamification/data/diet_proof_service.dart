import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DietLogType { photoProof, selfCheck, none }

class DietUploadResult {
  final bool success;
  final String? proofUrl;
  final DietLogType logType;
  final int pointsAwarded;
  final String? errorMessage;

  const DietUploadResult({
    required this.success,
    this.proofUrl,
    required this.logType,
    required this.pointsAwarded,
    this.errorMessage,
  });
}

final dietProofServiceProvider = Provider<DietProofService>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {}
  return DietProofService(client);
});

class DietProofService {
  final SupabaseClient? _client;
  final ImagePicker _picker;

  DietProofService([this._client, ImagePicker? picker])
      : _picker = picker ?? ImagePicker();

  Future<XFile?> pickMealPhoto({required ImageSource source}) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (_) {
      return null;
    }
  }

  Future<DietUploadResult> uploadMealProof({
    required String userId,
    required String filePath,
  }) async {
    if (_client == null) {
      return DietUploadResult(
        success: true,
        proofUrl: 'file://$filePath',
        logType: DietLogType.photoProof,
        pointsAwarded: 15,
      );
    }

    try {
      final fileName = 'proof_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);

      await _client.storage.from('diet_proofs').upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = _client.storage.from('diet_proofs').getPublicUrl(fileName);

      return DietUploadResult(
        success: true,
        proofUrl: publicUrl,
        logType: DietLogType.photoProof,
        pointsAwarded: 15,
      );
    } catch (e) {
      // If storage bucket isn't reachable, save local URI as fallback
      return DietUploadResult(
        success: true,
        proofUrl: filePath,
        logType: DietLogType.photoProof,
        pointsAwarded: 15,
        errorMessage: e.toString(),
      );
    }
  }

  DietUploadResult logSelfCheck() {
    return const DietUploadResult(
      success: true,
      proofUrl: null,
      logType: DietLogType.selfCheck,
      pointsAwarded: 2,
    );
  }
}
