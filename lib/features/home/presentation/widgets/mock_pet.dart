import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Visual-only pet summary used to mock the Home dashboard until the real
/// Pets feature is implemented.
class MockPet {
  const MockPet({
    required this.name,
    required this.breed,
    required this.details,
    required this.statusLabel,
    required this.statusColor,
    required this.avatarIcon,
  });

  final String name;
  final String breed;
  final String details;
  final String statusLabel;
  final Color statusColor;
  final IconData avatarIcon;
}

/// Static example data used purely to visualize the Home screen design.
const mockPets = <MockPet>[
  MockPet(
    name: 'Luna',
    breed: 'Golden Retriever',
    details: '2 años · Hembra · 25 kg',
    statusLabel: 'Saludable',
    statusColor: AppColors.success,
    avatarIcon: Icons.pets_rounded,
  ),
  MockPet(
    name: 'Max',
    breed: 'Pembroke Welsh Corgi',
    details: '1 año · Macho · 12 kg',
    statusLabel: 'En observación',
    statusColor: AppColors.warning,
    avatarIcon: Icons.pets_rounded,
  ),
];
