import 'dart:async';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:uuid/uuid.dart';

import '../data/species_catalog.dart';
import '../models/animal_species.dart';
import '../models/collection_card.dart';

/// Локальное хранилище коллекции карточек (Hive) + кэш энциклопедии.
class CollectionRepository {
  static const _cardsBox = 'cards_box';
  static const _metaBox = 'meta_box';

  Box<Map>? _cards;
  Box<dynamic>? _meta;

  Future<void> init() async {
    await Hive.initFlutter();
    _cards = await Hive.openBox<Map>(_cardsBox);
    _meta = await Hive.openBox<dynamic>(_metaBox);
  }

  List<CollectionCard> allCards() {
    final list = _cards?.values
            .map((m) =>
                CollectionCard.fromMap(Map<String, dynamic>.from(m), SpeciesCatalog.byId))
            .toList() ??
        <CollectionCard>[];
    list.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return list;
  }

  /// Добавить карточку в коллекцию (результат AR-поимки).
  Future<CollectionCard> addCard({
    required AnimalSpecies species,
    required Rarity rarity,
    required double lat,
    required double lon,
    String photoPath = '',
    bool isShiny = false,
  }) async {
    final card = CollectionCard(
      cardId: const Uuid().v4(),
      species: species,
      rarity: rarity,
      capturedAt: DateTime.now(),
      captureLat: lat,
      captureLon: lon,
      photoPath: photoPath,
      isShiny: isShiny,
    );
    await _cards?.put(card.cardId, card.toMap());
    await _incrementStat('totalCaptures');
    if (!await hasSpecies(species.speciesId)) {
      await _incrementStat('uniqueSpecies');
    }
    return card;
  }

  Future<bool> hasSpecies(String speciesId) async => allCards().any(
        (c) => c.species.speciesId == speciesId && c.status != CardStatus.tradedAway,
      );

  Future<void> updateCard(CollectionCard card) =>
      _cards?.put(card.cardId, card.toMap());

  Future<void> removeCard(String cardId) => _cards?.delete(cardId);

  /// Пометить карточку как переданную в трейде.
  Future<void> markTradedAway(String cardId) async {
    final m = _cards?.get(cardId);
    if (m == null) return;
    final card = CollectionCard.fromMap(Map<String, dynamic>.from(m), SpeciesCatalog.byId);
    await _cards?.put(cardId, {
      ...card.toMap(),
      'status': CardStatus.tradedAway.name,
      'tradeCount': card.tradeCount + 1,
    });
  }

  /// Получить карточку по id (для приёма трейда).
  CollectionCard? cardById(String id) {
    final m = _cards?.get(id);
    if (m == null) return null;
    return CollectionCard.fromMap(Map<String, dynamic>.from(m), SpeciesCatalog.byId);
  }

  int statTotalCaptures() => (_meta?.get('totalCaptures') as num?)?.toInt() ?? 0;
  int statUniqueSpecies() => (_meta?.get('uniqueSpecies') as num?)?.toInt() ?? 0;

  Future<void> _incrementStat(String key) async {
    final v = (_meta?.get(key) as num?)?.toInt() ?? 0;
    await _meta?.put(key, v + 1);
  }

  /// Сохранить снимок из камеры рядом с документом пользователя.
  static Future<String> savePhoto(List<int> bytes) async {
    final dir = await pp.getApplicationDocumentsDirectory();
    final photos = Directory('${dir.path}/photos');
    if (!photos.existsSync()) photos.createSync(recursive: true);
    final file = File('${photos.path}/${const Uuid().v4()}.jpg');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
