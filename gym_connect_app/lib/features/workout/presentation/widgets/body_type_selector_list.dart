import 'package:flutter/material.dart';
import 'body_type_card.dart';

class BodyTypeSelectorList extends StatelessWidget {
  final String selectedBodyType;
  final ValueChanged<String> onSelect;

  const BodyTypeSelectorList({
    super.key,
    required this.selectedBodyType,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        BodyTypeCard(
          title: 'ECTOMORPH',
          subtitle: 'Lean / Fast Burner',
          description: 'Fast metabolism & lean build. Requires caloric surplus and hyper-focused compound volume.',
          targetPhysique: 'Outcome: Shredded Athletic V-Taper (6-8% Body Fat)',
          imageAsset: 'assets/images/ectomorph.jpg',
          icon: Icons.speed_rounded,
          isSelected: selectedBodyType == 'ectomorph',
          onTap: () => onSelect('ectomorph'),
        ),
        BodyTypeCard(
          title: 'MESOMORPH',
          subtitle: 'Athletic / V-Taper',
          description: 'Naturally broad and muscular. Rapid response to progressive overload hypertrophy.',
          targetPhysique: 'Outcome: Dense Muscular Beast (Full Chest & Wide Lats)',
          imageAsset: 'assets/images/mesomorph.jpg',
          icon: Icons.fitness_center_rounded,
          isSelected: selectedBodyType == 'mesomorph',
          onTap: () => onSelect('mesomorph'),
        ),
        BodyTypeCard(
          title: 'ENDOMORPH',
          subtitle: 'Dense / High Power',
          description: 'Thick bone density and raw lifting power. Combined with metabolic conditioning burn.',
          targetPhysique: 'Outcome: Solid Powerlifter Physique (Chiseled Mass)',
          imageAsset: 'assets/images/endomorph.jpg',
          icon: Icons.shield_rounded,
          isSelected: selectedBodyType == 'endomorph',
          onTap: () => onSelect('endomorph'),
        ),
      ],
    );
  }
}
