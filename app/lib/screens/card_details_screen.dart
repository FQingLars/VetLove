import 'dart:io';

import 'package:flutter/material.dart';

import '../models/collection_card.dart';
import '../widgets/rarity_widgets.dart';

/// Энциклопедическая карточка вида + статистика конкретного экземпляра.
class CardDetailsScreen extends StatelessWidget {
  const CardDetailsScreen({super.key, required this.card});

  final CollectionCard card;

  @override
  Widget build(BuildContext context) {
    final s = card.species;
    return Scaffold(
      appBar: AppBar(title: Text(s.nameRu)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(card: card),
          const SizedBox(height: 16),
          Text(
            s.description,
            style: const TextStyle(height: 1.4, fontSize: 15),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Научное название', value: s.scientificName),
          _InfoRow(label: 'Таксономия', value: s.taxonomy),
          _InfoRow(label: 'Ареал', value: s.habitat),
          _InfoRow(label: 'Питание', value: s.diet),
          _InfoRow(label: 'Продолжительность жизни', value: s.lifespan),
          _InfoRow(label: 'Размер', value: s.sizeInfo),
          _InfoRow(label: 'Охранный статус МСОП', value: s.iucnStatus),
          _InfoRow(
            label: 'Дата поимки',
            value: _formatDate(card.capturedAt),
          ),
          _InfoRow(label: 'Уровень', value: '${card.level}'),
          _InfoRow(
            label: 'Участий в трейдах',
            value: '${card.tradeCount}',
          ),
          if (card.status != CardStatus.owned)
            _InfoRow(label: 'Статус', value: _statusLabel(card.status)),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

  static String _statusLabel(CardStatus s) => switch (s) {
        CardStatus.owned => 'В коллекции',
        CardStatus.listedForTrade => 'Выставлен на обмен',
        CardStatus.tradedAway => 'Отдан в трейде',
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.card});

  final CollectionCard card;

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(card.rarity);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.25), color.withOpacity(0.05)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: card.photoPath.isNotEmpty &&
                      File(card.photoPath).existsSync()
                  ? Image.file(File(card.photoPath), fit: BoxFit.cover)
                  : Container(
                      color: Colors.blueGrey.shade100,
                      child: Icon(
                        Icons.pets,
                        size: 72,
                        color: color,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            card.species.nameRu,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            card.species.scientificName,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RarityBadge(rarity: card.rarity),
              RarityStars(rarity: card.rarity),
              if (card.isShiny)
                const Chip(
                  avatar: Icon(Icons.auto_awesome, size: 16),
                  label: Text('Блестящая'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
