import 'package:flutter/material.dart';

import '../models/animal_species.dart';

/// Виджеты редкости: звёзды и цвет рамки карточки.
class RarityStars extends StatelessWidget {
  const RarityStars({super.key, required this.rarity, this.size = 16});

  final Rarity rarity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rarity.stars;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? rarityColor(rarity) : Colors.grey.shade400,
        );
      }),
    );
  }
}

Color rarityColor(Rarity r) => switch (r) {
      Rarity.common => const Color(0xFF9E9E9E),
      Rarity.uncommon => const Color(0xFF66BB6A),
      Rarity.rare => const Color(0xFF42A5F5),
      Rarity.epic => const Color(0xFFAB47BC),
      Rarity.legendary => const Color(0xFFFFB300),
    };

String rarityLabel(Rarity r) => '${r.labelRu} (${r.stars}★)';

class RarityBadge extends StatelessWidget {
  const RarityBadge({super.key, required this.rarity});

  final Rarity rarity;

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        rarityLabel(rarity),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
