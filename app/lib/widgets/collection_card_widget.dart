import 'dart:io';

import 'package:flutter/material.dart';

import '../models/animal_species.dart';
import '../models/collection_card.dart';
import 'rarity_widgets.dart';

/// Карточка коллекции в стиле «покемон-карты»: фото/иллюстрация, имя, звёзды.
class CollectionCardWidget extends StatelessWidget {
  const CollectionCardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.selected = false,
    this.compact = false,
  });

  final CollectionCard card;
  final VoidCallback? onTap;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(card.rarity);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white : color,
            width: selected ? 3 : 2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.35),
              Theme.of(context).colorScheme.surface,
            ],
          ),
          boxShadow: [
            if (card.isShiny || card.rarity == Rarity.legendary)
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 1,
              ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: card.photoPath.isNotEmpty &&
                            File(card.photoPath).existsSync()
                        ? Image.file(File(card.photoPath), fit: BoxFit.cover)
                        : _placeholder(),
                  ),
                  if (card.isShiny)
                    const Positioned(
                      right: 4,
                      top: 4,
                      child: Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                    ),
                  if (card.status == CardStatus.listedForTrade)
                    const Positioned(
                      left: 4,
                      bottom: 4,
                      child: Chip(
                        label: Text('В обмене', style: TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card.species.nameRu,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (!compact)
              Text(
                card.species.scientificName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontStyle: FontStyle.italic, fontSize: 11, color: Colors.grey.shade600),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RarityStars(rarity: card.rarity, size: 14),
                Text('ур.${card.level}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.blueGrey.shade100,
        child: Icon(pawIcon(), size: 48, color: rarityColor(card.rarity)),
      );

  IconData pawIcon() {
    final t = card.species.taxonomy;
    if (t.contains('Птицы')) return Icons.flight;
    if (t.contains('Пресмыкающиеся')) return Icons.pool;
    if (t.contains('китообразные')) return Icons.waves;
    return Icons.pets;
  }
}
