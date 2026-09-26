import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/user_role.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../data/workout_repository.dart';
import '../../domain/models/workout_models.dart';

class BodyTypesCatalogNotifier extends AsyncNotifier<List<BodyTypeInfo>> {
  @override
  Future<List<BodyTypeInfo>> build() async {
    final auth = ref.watch(authNotifierProvider);
    final tenantId = (auth is AuthAuthenticated) ? auth.profile.tenantId : null;
    final repo = ref.watch(workoutRepositoryProvider);
    return repo.fetchBodyTypesCatalog(tenantId: tenantId);
  }

  Future<bool> updateBodyType({
    required String bodyType,
    required String title,
    required String subtitle,
    required String description,
    required String targetPhysique,
    String? imageUrl,
    List<String>? galleryImages,
  }) async {
    final auth = ref.read(authNotifierProvider);
    final isAuthorized = (auth is AuthAuthenticated) &&
        (auth.activeRole == UserRole.superAdmin || auth.activeRole == UserRole.owner);
    if (!isAuthorized) return false;

    final tenantId = auth.profile.tenantId;
    final repo = ref.read(workoutRepositoryProvider);
    final ok = await repo.updateBodyTypeProtocolInfo(
      bodyType: bodyType,
      tenantId: tenantId,
      title: title,
      subtitle: subtitle,
      description: description,
      targetPhysique: targetPhysique,
      imageUrl: imageUrl,
      galleryImages: galleryImages,
    );

    if (ok) {
      ref.invalidateSelf();
    }
    return ok;
  }
}

final bodyTypesCatalogProvider =
    AsyncNotifierProvider<BodyTypesCatalogNotifier, List<BodyTypeInfo>>(
  BodyTypesCatalogNotifier.new,
);
