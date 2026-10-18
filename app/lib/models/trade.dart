import 'collection_card.dart';

/// Тип сделки.
enum TradeType { simple, multi } // 1-на-1 / N-на-M

/// Состояние трейда.
enum TradeState {
  proposed, // отправлен
  accepted, // принят второй стороной, ожидает подтверждения условий
  completed,
  cancelled,
  expired,
}

/// Профиль пользователя (со стороны бэкенда/Firestore).
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.nickname,
    this.photoUrl = '',
    this.level = 1,
    this.xp = 0,
    this.lastLat = 0,
    this.lastLon = 0,
    this.createdAt,
  });

  final String uid;
  final String nickname;
  final String photoUrl;
  final int level;
  final int xp;

  /// Последняя известная позиция — используется для поиска партнёров «поблизости».
  final double lastLat;
  final double lastLon;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'nickname': nickname,
        'photoUrl': photoUrl,
        'level': level,
        'xp': xp,
        'lastLat': lastLat,
        'lastLon': lastLon,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        uid: m['uid'] as String,
        nickname: m['nickname'] as String? ?? 'Игрок',
        photoUrl: m['photoUrl'] as String? ?? '',
        level: (m['level'] as num?)?.toInt() ?? 1,
        xp: (m['xp'] as num?)?.toInt() ?? 0,
        lastLat: (m['lastLat'] as num?)?.toDouble() ?? 0,
        lastLon: (m['lastLon'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? ''),
      );
}

/// Публичное объявление: пользователь выставляет карточки за карточки.
class TradeListing {
  const TradeListing({
    required this.listingId,
    required this.ownerUid,
    required this.ownerName,
    required this.offeredCards,
    required this.wantedCards,
    required this.createdAt,
    required this.lat,
    required this.lon,
  });

  final String listingId;
  final String ownerUid;
  final String ownerName;
  final List<CardRef> offeredCards;
  final List<CardRef> wantedCards;
  final DateTime createdAt;
  final double lat;
  final double lon;

  Map<String, dynamic> toMap() => {
        'listingId': listingId,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'offeredCards': offeredCards.map((c) => c.toMap()).toList(),
        'wantedCards': wantedCards.map((c) => c.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'lat': lat,
        'lon': lon,
      };

  factory TradeListing.fromMap(Map<String, dynamic> m) => TradeListing(
        listingId: m['listingId'] as String,
        ownerUid: m['ownerUid'] as String,
        ownerName: m['ownerName'] as String? ?? '?',
        offeredCards: (m['offeredCards'] as List? ?? [])
            .map((e) => CardRef.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        wantedCards: (m['wantedCards'] as List? ?? [])
            .map((e) => CardRef.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAt:
            DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
        lat: (m['lat'] as num?)?.toDouble() ?? 0,
        lon: (m['lon'] as num?)?.toDouble() ?? 0,
      );
}

/// Лёгкая ссылка на карточку для сетевых сообщений трейда.
class CardRef {
  const CardRef({
    required this.cardId,
    required this.speciesId,
    required this.speciesName,
    required this.rarityStars,
    this.isShiny = false,
    this.level = 1,
  });

  final String cardId;
  final String speciesId;
  final String speciesName;
  final int rarityStars;
  final bool isShiny;
  final int level;

  static CardRef fromCard(CollectionCard c) => CardRef(
        cardId: c.cardId,
        speciesId: c.species.speciesId,
        speciesName: c.species.nameRu,
        rarityStars: c.rarity.stars,
        isShiny: c.isShiny,
        level: c.level,
      );

  Map<String, dynamic> toMap() => {
        'cardId': cardId,
        'speciesId': speciesId,
        'speciesName': speciesName,
        'rarityStars': rarityStars,
        'isShiny': isShiny,
        'level': level,
      };

  factory CardRef.fromMap(Map<String, dynamic> m) => CardRef(
        cardId: m['cardId'] as String,
        speciesId: m['speciesId'] as String,
        speciesName: m['speciesName'] as String? ?? '?',
        rarityStars: (m['rarityStars'] as num?)?.toInt() ?? 1,
        isShiny: m['isShiny'] as bool? ?? false,
        level: (m['level'] as num?)?.toInt() ?? 1,
      );
}

/// Активная сделка между двумя пользователями.
class TradeOffer {
  const TradeOffer({
    required this.tradeId,
    required this.fromUid,
    required this.fromName,
    required this.toUid,
    required this.toName,
    required this.give,
    required this.receive,
    required this.state,
    required this.createdAt,
    required this.expiresAt,
    this.type = TradeType.simple,
  });

  final String tradeId;
  final String fromUid;
  final String fromName;
  final String toUid;
  final String toName;

  /// Что предлагает отправитель и что он хочет получить.
  final List<CardRef> give;
  final List<CardRef> receive;

  final TradeState state;
  final DateTime createdAt;
  final DateTime expiresAt;
  final TradeType type;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() => {
        'tradeId': tradeId,
        'fromUid': fromUid,
        'fromName': fromName,
        'toUid': toUid,
        'toName': toName,
        'give': give.map((c) => c.toMap()).toList(),
        'receive': receive.map((c) => c.toMap()).toList(),
        'state': state.name,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'type': type.name,
      };

  factory TradeOffer.fromMap(Map<String, dynamic> m) => TradeOffer(
        tradeId: m['tradeId'] as String,
        fromUid: m['fromUid'] as String,
        fromName: m['fromName'] as String? ?? '?',
        toUid: m['toUid'] as String,
        toName: m['toName'] as String? ?? '?',
        give: (m['give'] as List? ?? [])
            .map((e) => CardRef.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        receive: (m['receive'] as List? ?? [])
            .map((e) => CardRef.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        state: TradeState.values.firstWhere(
          (s) => s.name == m['state'],
          orElse: () => TradeState.proposed,
        ),
        createdAt:
            DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
        expiresAt: DateTime.tryParse(m['expiresAt'] as String? ?? '') ??
            DateTime.now().add(const Duration(hours: 24)),
        type: TradeType.values.firstWhere(
          (t) => t.name == m['type'],
          orElse: () => TradeType.simple,
        ),
      );
}
