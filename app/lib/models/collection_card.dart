import 'animal_species.dart';

/// Статус карточки в коллекции игрока.
enum CardStatus { owned, listedForTrade, tradedAway }

/// Карточка животного в коллекции пользователя.
class CollectionCard {
  const CollectionCard({
    required this.cardId,
    required this.species,
    required this.rarity,
    required this.capturedAt,
    required this.captureLat,
    required this.captureLon,
    required this.photoPath,
    this.level = 1,
    this.exp = 0,
    this.status = CardStatus.owned,
    this.isShiny = false,
    this.tradeCount = 0,
  });

  final String cardId;
  final AnimalSpecies species;

  /// Итоговая редкость, выпавшая при поимке (1–5 звёзд).
  final Rarity rarity;

  final DateTime capturedAt;

  /// Координаты точки поимки (для «гео-памяти» и статистики).
  final double captureLat;
  final double captureLon;

  /// Локальный снимок, сделанный в AR-моменте (путь к файлу).
  final String photoPath;

  final int level;
  final int exp;
  final CardStatus status;

  /// Особая «блестящая» вариация (шанс ~2%).
  final bool isShiny;

  /// Сколько раз карточка участвовала в трейдах.
  final int tradeCount;

  bool get canTrade => status == CardStatus.owned;

  Map<String, dynamic> toMap() => {
        'cardId': cardId,
        'speciesId': species.speciesId,
        'rarityStars': rarity.stars,
        'capturedAt': capturedAt.toIso8601String(),
        'captureLat': captureLat,
        'captureLon': captureLon,
        'photoPath': photoPath,
        'level': level,
        'exp': exp,
        'status': status.name,
        'isShiny': isShiny,
        'tradeCount': tradeCount,
      };

  factory CollectionCard.fromMap(
          Map<String, dynamic> m, AnimalSpecies Function(String id) resolve) =>
      CollectionCard(
        cardId: m['cardId'] as String,
        species: resolve(m['speciesId'] as String),
        rarity: Rarity.fromStars((m['rarityStars'] as num?)?.toInt() ?? 1),
        capturedAt: DateTime.tryParse(m['capturedAt'] as String? ?? '') ??
            DateTime.now(),
        captureLat: (m['captureLat'] as num?)?.toDouble() ?? 0.0,
        captureLon: (m['captureLon'] as num?)?.toDouble() ?? 0.0,
        photoPath: m['photoPath'] as String? ?? '',
        level: (m['level'] as num?)?.toInt() ?? 1,
        exp: (m['exp'] as num?)?.toInt() ?? 0,
        status: CardStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => CardStatus.owned,
        ),
        isShiny: m['isShiny'] as bool? ?? false,
        tradeCount: (m['tradeCount'] as num?)?.toInt() ?? 0,
      );
}
