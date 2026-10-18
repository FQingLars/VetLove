/// Редкость карточки — от 1 до 5 звёзд.
enum Rarity {
  common(1, 'Обычный', 0.45),
  uncommon(2, 'Необычный', 0.28),
  rare(3, 'Редкий', 0.17),
  epic(4, 'Эпический', 0.08),
  legendary(5, 'Легендарный', 0.02);

  const Rarity(this.stars, this.labelRu, this.probability);

  final int stars;
  final String labelRu;
  final double probability;

  static Rarity fromStars(int s) =>
      Rarity.values.firstWhere((r) => r.stars == s, orElse: () => Rarity.common);
}

/// Энциклопедическая справка о виде животного.
class AnimalSpecies {
  const AnimalSpecies({
    required this.speciesId,
    required this.nameRu,
    required this.scientificName,
    required this.taxonomy,
    required this.habitat,
    required this.description,
    required this.diet,
    required this.lifespan,
    required this.sizeInfo,
    required this.iucnStatus,
    required this.baseRarityStars,
    required this.imagePath,
    this.regions = const [],
    this.inaturalistTaxonId,
  });

  /// Уникальный код вида (например `lynx_lynx`).
  final String speciesId;

  /// Название на русском.
  final String nameRu;

  /// Латинское (научное) название.
  final String scientificName;

  /// Отряд/семейство — таксономия.
  final String taxonomy;

  /// Ареал обитания.
  final String habitat;

  /// Краткое энциклопедическое описание.
  final String description;

  /// Питание.
  final String diet;

  /// Продолжительность жизни.
  final String lifespan;

  /// Размер (длина/масса).
  final String sizeInfo;

  /// Охранный статус МСОП (LC, NT, VU, EN, CR).
  final String iucnStatus;

  /// Базовая редкость вида в игре (влияет на дроп-таблицу).
  final int baseRarityStars;

  /// Путь к локальному изображению/иллюстрации вида.
  final String imagePath;

  /// Регионы, где вид встречается в AR-спавне.
  final List<String> regions;

  /// ID таксона в iNaturalist (используется для распознавания через API).
  final int? inaturalistTaxonId;

  Rarity get baseRarity => Rarity.fromStars(baseRarityStars);

  Map<String, dynamic> toMap() => {
        'speciesId': speciesId,
        'nameRu': nameRu,
        'scientificName': scientificName,
        'taxonomy': taxonomy,
        'habitat': habitat,
        'description': description,
        'diet': diet,
        'lifespan': lifespan,
        'sizeInfo': sizeInfo,
        'iucnStatus': iucnStatus,
        'baseRarityStars': baseRarityStars,
        'imagePath': imagePath,
        'regions': regions,
        'inaturalistTaxonId': inaturalistTaxonId,
      };

  factory AnimalSpecies.fromMap(Map<String, dynamic> m) => AnimalSpecies(
        speciesId: m['speciesId'] as String,
        nameRu: m['nameRu'] as String,
        scientificName: m['scientificName'] as String? ?? '',
        taxonomy: m['taxonomy'] as String? ?? '',
        habitat: m['habitat'] as String? ?? '',
        description: m['description'] as String? ?? '',
        diet: m['diet'] as String? ?? '',
        lifespan: m['lifespan'] as String? ?? '',
        sizeInfo: m['sizeInfo'] as String? ?? '',
        iucnStatus: m['iucnStatus'] as String? ?? 'LC',
        baseRarityStars: (m['baseRarityStars'] as num?)?.toInt() ?? 1,
        imagePath: m['imagePath'] as String? ?? '',
        regions: (m['regions'] as List?)?.cast<String>() ?? const [],
        inaturalistTaxonId: (m['inaturalistTaxonId'] as num?)?.toInt(),
      );
}
