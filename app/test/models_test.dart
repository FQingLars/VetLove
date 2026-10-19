import 'package:critter_collect/data/species_catalog.dart';
import 'package:critter_collect/models/animal_species.dart';
import 'package:critter_collect/models/collection_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rarity', () {
    test('fromStars сопоставляет редкость по числу звёзд', () {
      expect(Rarity.fromStars(1), Rarity.common);
      expect(Rarity.fromStars(3), Rarity.rare);
      expect(Rarity.fromStars(5), Rarity.legendary);
    });

    test('fromStars для неизвестного значения даёт common', () {
      expect(Rarity.fromStars(0), Rarity.common);
      expect(Rarity.fromStars(9), Rarity.common);
    });

    test('у каждой редкости своё число звёзд', () {
      final stars = Rarity.values.map((r) => r.stars).toSet();
      expect(stars.length, Rarity.values.length);
    });
  });

  group('SpeciesCatalog', () {
    test('каталог непустой, идентификаторы уникальны', () {
      expect(SpeciesCatalog.all, isNotEmpty);
      final ids = SpeciesCatalog.all.map((s) => s.speciesId).toSet();
      expect(ids.length, SpeciesCatalog.all.length);
    });

    test('byId возвращает вид из каталога', () {
      expect(SpeciesCatalog.byId('lynx_lynx').nameRu, 'Рысь евразийская');
    });

    test('byId для неизвестного id даёт заглушку', () {
      final stub = SpeciesCatalog.byId('no_such_species');
      expect(stub.nameRu, 'no_such_species');
      expect(stub.baseRarity, Rarity.common);
    });

    test('inRegion отбирает только виды своего региона', () {
      final forest = SpeciesCatalog.inRegion('forest');
      expect(forest, isNotEmpty);
      for (final s in forest) {
        expect(s.regions, contains('forest'));
      }
    });
  });

  group('CollectionCard', () {
    CollectionCard make() => CollectionCard(
          cardId: 'c1',
          species: SpeciesCatalog.all.first,
          rarity: Rarity.epic,
          capturedAt: DateTime.utc(2026, 1, 2),
          captureLat: 1.5,
          captureLon: 2.5,
          photoPath: '',
          isShiny: true,
        );

    test('toMap и fromMap сохраняют поля карточки', () {
      final source = make();
      final restored =
          CollectionCard.fromMap(source.toMap(), SpeciesCatalog.byId);

      expect(restored.cardId, source.cardId);
      expect(restored.rarity, Rarity.epic);
      expect(restored.isShiny, isTrue);
      expect(restored.capturedAt, source.capturedAt);
      expect(restored.species.speciesId, source.species.speciesId);
    });

    test('карточка без статуса owned не участвует в трейдах', () {
      expect(make().canTrade, isTrue);

      final traded = CollectionCard.fromMap(
        {...make().toMap(), 'status': CardStatus.tradedAway.name},
        SpeciesCatalog.byId,
      );
      expect(traded.canTrade, isFalse);
    });
  });
}
