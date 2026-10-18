import 'package:flutter/foundation.dart';

import '../data/species_catalog.dart';
import '../models/animal_species.dart';
import '../models/collection_card.dart';
import '../services/collection_repository.dart';

/// Состояние коллекции: карточки, фильтры, прогресс по энциклопедии.
class CollectionProvider extends ChangeNotifier {
  CollectionProvider(this._repo);

  final CollectionRepository _repo;

  List<CollectionCard> _cards = [];
  Rarity? _rarityFilter;
  String _query = '';
  bool _showTradedAway = false;

  List<CollectionCard> get cards => _cards;

  Rarity? get rarityFilterValue => _rarityFilter;

  List<CollectionCard> get visible {
    Iterable<CollectionCard> it = _cards;
    if (!_showTradedAway) {
      it = it.where((c) => c.status != CardStatus.tradedAway);
    }
    if (_rarityFilter != null) {
      it = it.where((c) => c.rarity == _rarityFilter);
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      it = it.where((c) =>
          c.species.nameRu.toLowerCase().contains(q) ||
          c.species.scientificName.toLowerCase().contains(q));
    }
    return it.toList();
  }

  int totalCaptures() => _repo.statTotalCaptures();
  int uniqueSpecies() => _repo.statUniqueSpecies();
  int dexProgress() => uniqueSpecies();
  int dexTotal() => SpeciesCatalog.all.length;

  double collectionPower() => _cards
      .where((c) => c.status != CardStatus.tradedAway)
      .fold(0.0, (sum, c) => sum + c.rarity.stars * c.level + (c.isShiny ? 10 : 0));

  Future<void> load() async {
    _cards = _repo.allCards();
    notifyListeners();
  }

  Future<CollectionCard> capture({
    required AnimalSpecies species,
    required Rarity rarity,
    required double lat,
    required double lon,
    String photoPath = '',
    bool isShiny = false,
  }) async {
    final card = await _repo.addCard(
      species: species,
      rarity: rarity,
      lat: lat,
      lon: lon,
      photoPath: photoPath,
      isShiny: isShiny,
    );
    await load();
    return card;
  }

  Future<void> setRarityFilter(Rarity? r) async {
    _rarityFilter = r;
    notifyListeners();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void toggleShowTradedAway() {
    _showTradedAway = !_showTradedAway;
    notifyListeners();
  }

  /// Карточка уже есть в коллекции (для бейджа «новый вид!» при поимке).
  bool isNewSpecies(String speciesId) =>
      !_cards.any((c) =>
          c.species.speciesId == speciesId && c.status != CardStatus.tradedAway);

  CollectionCard? byId(String id) => _repo.cardById(id);
}
