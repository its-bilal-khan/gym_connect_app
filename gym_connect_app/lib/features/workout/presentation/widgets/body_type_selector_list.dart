import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/user_role.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../providers/body_types_catalog_provider.dart';
import 'body_type_card.dart';
import 'edit_body_type_dialog.dart';
import '../../domain/models/workout_models.dart';

class BodyTypeSelectorList extends ConsumerWidget {
  final String selectedBodyType;
  final ValueChanged<String> onSelect;

  const BodyTypeSelectorList({
    super.key,
    required this.selectedBodyType,
    required this.onSelect,
  });

  static const _defaultIcons = {
    'ectomorph': Icons.speed_rounded,
    'mesomorph': Icons.fitness_center_rounded,
    'endomorph': Icons.shield_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(bodyTypesCatalogProvider);
    final authState = ref.watch(authNotifierProvider);
    final canEdit = (authState is AuthAuthenticated) &&
        (authState.activeRole == UserRole.superAdmin || authState.activeRole == UserRole.owner);

    final catalog = catalogAsync.asData?.value ?? const [
      BodyTypeInfo(
        key: 'ectomorph',
        title: 'ECTOMORPH',
        subtitle: 'Lean / Fast Burner',
        description: 'Fast metabolism & lean build. Requires caloric surplus and hyper-focused compound volume.',
        targetPhysique: 'Outcome: Shredded Athletic V-Taper (6-8% Body Fat)',
        defaultImageAsset: 'assets/images/ectomorph.jpg',
      ),
      BodyTypeInfo(
        key: 'mesomorph',
        title: 'MESOMORPH',
        subtitle: 'Athletic / V-Taper',
        description: 'Naturally broad and muscular. Rapid response to progressive overload hypertrophy.',
        targetPhysique: 'Outcome: Dense Muscular Beast (Full Chest & Wide Lats)',
        defaultImageAsset: 'assets/images/mesomorph.jpg',
      ),
      BodyTypeInfo(
        key: 'endomorph',
        title: 'ENDOMORPH',
        subtitle: 'Dense / High Power',
        description: 'Thick bone density and raw lifting power. Combined with metabolic conditioning burn.',
        targetPhysique: 'Outcome: Solid Powerlifter Physique (Chiseled Mass)',
        defaultImageAsset: 'assets/images/endomorph.jpg',
      ),
    ];

    return ListView(
      children: catalog.map((item) {
        final icon = _defaultIcons[item.key] ?? Icons.fitness_center_rounded;
        return BodyTypeCard(
          info: item,
          title: item.title,
          subtitle: item.subtitle,
          description: item.description,
          targetPhysique: item.targetPhysique,
          imageAsset: item.defaultImageAsset,
          networkImageUrl: item.imageUrl,
          icon: icon,
          isSelected: selectedBodyType == item.key,
          onTap: () => onSelect(item.key),
          onCustomImageTap: canEdit ? () => EditBodyTypeDialog.show(context, item) : null,
        );
      }).toList(),
    );
  }
}
