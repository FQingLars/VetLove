import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/animal_species.dart';
import '../models/collection_card.dart';
import '../providers/collection_provider.dart';
import '../widgets/collection_card_widget.dart';
import '../widgets/rarity_widgets.dart';
import 'card_details_screen.dart';

/// Коллекция игрока: сет карточек + фильтры + прогресс энциклопедии.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<CollectionProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CollectionProvider>();
    final cards = prov.visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя коллекция'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(92),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Поиск вида…',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onChanged: prov.setQuery,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Показать отданные в трейдах',
                      onPressed: prov.toggleShowTradedAway,
                      icon: Icon(prov.cards.any((c) => c.status == CardStatus.tradedAway)
                          ? Icons.swap_horiz
                          : Icons.swap_horiz_outlined),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Все'),
                      selected: prov.rarityFilterValue == null,
                      onSelected: (_) => prov.setRarityFilter(null),
                    ),
                    ...Rarity.values.map((r) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            avatar: Icon(Icons.star_rounded,
                                size: 16, color: rarityColor(r)),
                            label: Text('${r.stars}★'),
                            selected: prov.rarityFilterValue == r,
                            onSelected: (sel) =>
                                prov.setRarityFilter(sel ? r : null),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(label: 'Всего поимок', value: '${prov.totalCaptures()}'),
                _Stat(
                    label: 'Видов в энциклопедии',
                    value: '${prov.dexProgress()}/${prov.dexTotal()}'),
                _Stat(
                    label: 'Сила коллекции',
                    value: prov.collectionPower().round().toString()),
              ],
            ),
          ),
          Expanded(
            child: cards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_camera_outlined, size: 48),
                        const SizedBox(height: 8),
                        const Text('Пока пусто — найдите животное через AR-скан!'),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Открыть камеру'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.66,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (_, i) {
                      final card = cards[i];
                      return CollectionCardWidget(
                        card: card,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => CardDetailsScreen(card: card))),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
