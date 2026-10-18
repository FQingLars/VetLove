import 'dart:math';
import 'dart:typed_data';

import '../data/species_catalog.dart';
import '../models/animal_species.dart';
import 'inaturalist_service.dart';

/// Результат распознавания животного в кадре камеры.
class DetectionResult {
  const DetectionResult({
    required this.species,
    required this.confidence,
    required this.box,
    this.fromApi = false,
    this.photoUrl,
  });

  final AnimalSpecies species;

  /// Уверенность модели 0..1.
  final double confidence;

  /// Ограничивающий прямоугольник в нормализованных координатах кадра (0..1):
  /// left, top, width, height.
  final Rect4 box;

  /// Распознано через внешний API (iNaturalist), а не локальным дропом.
  final bool fromApi;

  /// Фото таксона из iNaturalist (для превью карточки при онлайн-поимке).
  final String? photoUrl;
}

class Rect4 {
  const Rect4(this.left, this.top, this.width, this.height);
  final double left, top, width, height;
}

/// Сервис распознавания животных по кадру с камеры.
///
/// Классификация видов вынесена во внешний **iNaturalist REST API**
/// (`POST /vision/score`): серверная vision-модель обучена на миллионах
/// наблюдений и использует гео-приор по координатам съёмки. Это избавляет
/// приложение от необходимости тащить и дообучать собственную TFLite-модель
/// (размер APK/IPA, расход батареи, качество на длинном хвосте видов).
///
/// Если сеть недоступна или уверенность API ниже [minApiConfidence],
/// включается офлайн-фолбэк — локальный спавн из каталога по георегиону,
/// чтобы AR-режим работал и без интернета.
class AnimalRecognitionService {
  AnimalRecognitionService({
    Random? random,
    InaturalistService? inat,
    this.minApiConfidence = 0.10,
  })  : _random = random ?? Random.secure(),
        _inat = inat ?? InaturalistService();

  final Random _random;
  final InaturalistService _inat;

  /// Порог composite-уверенности iNaturalist, ниже которого результат
  /// считается нераспознанным и происходит fallback на локальный спавн.
  final double minApiConfidence;

  bool _initialized = false;
  DateTime? _lastApiCall;

  /// Минимальный интервал между обращениями к /vision/score
  /// (rate-limit + экономия трафика).
  static const _apiCooldown = Duration(milliseconds: 1200);

  Future<void> init() async {
    _initialized = true;
  }

  /// Проанализировать кадр (JPEG bytes) и вернуть распознанных «животных».
  ///
  /// [frame] — сжатое изображение кадра (в проде: `image.getBytes(jpgQuality: 80)`).
  /// [region] — гео-регион игрока для офлайн-спавна (forest/urban/…).
  /// [lat]/[lon] — координаты: повышают точность vision-модели iNat.
  Future<List<DetectionResult>> detect(
    Uint8List? frame,
    String region, {
    double? lat,
    double? lon,
  }) async {
    if (!_initialized) await init();

    // 1) Пытаемся распознать через iNaturalist API.
    if (frame != null && frame.isNotEmpty && !_inCooldown()) {
      try {
        final candidates = await _inat.scoreImage(frame, lat: lat, lon: lon);
        _lastApiCall = DateTime.now();
        final mapped = candidates
            .where((c) => c.compositeScore >= minApiConfidence)
            .map(_toDetection)
            .whereType<DetectionResult>()
            .take(3)
            .toList();
        if (mapped.isNotEmpty) return mapped;
      } on Exception {
        // Сеть/лимит недоступен — уходим в офлайн-фолбэк.
      }
    }

    // 2) Офлайн-фолбэк: эвристический локальный спавн по региону.
    return _offlineSpawn(region, frame);
  }

  bool _inCooldown() =>
      _lastApiCall != null &&
      DateTime.now().difference(_lastApiCall!) < _apiCooldown;

  /// Маппинг кандидата iNaturalist на вид локального каталога.
  ///
  /// Совпадение по `inaturalistTaxonId`; если API вернул вид, которого нет
  /// в игровом каталоге, создаётся «дикий» вид — бонус-находка вне энциклопедии.
  DetectionResult _toDetection(ScoreCandidate c) {
    final known = SpeciesCatalog.all
        .where((s) => s.inaturalistTaxonId == c.taxonId)
        .firstOrNull;
    final species = known ??
        AnimalSpecies(
          speciesId: 'inat_${c.taxonId}',
          nameRu: c.commonName.isNotEmpty ? c.commonName : c.scientificName,
          scientificName: c.scientificName,
          taxonomy: 'Распознано iNaturalist (${c.rank ?? 'sp.'})',
          habitat: '',
          description: 'Вид ещё не внесён в игровую энциклопедию. '
              'Данные подтянуты из сообщества iNaturalist.',
          diet: '',
          lifespan: '',
          sizeInfo: '',
          iucnStatus: 'LC',
          baseRarityStars: c.compositeScore > 0.9 ? 4 : 3,
          imagePath: '',
          regions: const [],
          inaturalistTaxonId: c.taxonId,
        );
    return DetectionResult(
      species: species,
      confidence: c.compositeScore,
      box: const Rect4(0.2, 0.2, 0.5, 0.5),
      fromApi: true,
      photoUrl: c.imageUrl,
    );
  }

  /// Локальный генератор находок без сети (гео-регион + дроп-таблица).
  List<DetectionResult> _offlineSpawn(String region, Uint8List? frame) {
    final seed = (frame?.length ?? 0) + DateTime.now().microsecondsSinceEpoch;
    final rnd = Random(seed);

    final pool = SpeciesCatalog.inRegion(region);
    if (pool.isEmpty) return const [];

    final results = <DetectionResult>[];
    final n = rnd.nextBool() ? 1 : (rnd.nextDouble() < 0.25 ? 2 : 1);
    for (var i = 0; i < n; i++) {
      final species = _rollSpecies(pool, rnd);
      final confidence = 0.55 + rnd.nextDouble() * 0.44;
      results.add(DetectionResult(
        species: species,
        confidence: confidence,
        box: Rect4(
          0.1 + rnd.nextDouble() * 0.3,
          0.15 + rnd.nextDouble() * 0.3,
          0.3 + rnd.nextDouble() * 0.25,
          0.3 + rnd.nextDouble() * 0.3,
        ),
      ));
    }
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  AnimalSpecies _rollSpecies(List<AnimalSpecies> pool, Random rnd) {
    // Виды с меньшей базовой редкостью выпадают чаще.
    final weights = pool.map((s) => 1.0 / pow(s.baseRarityStars, 1.6)).toList();
    final total = weights.reduce((a, b) => a + b);
    var x = rnd.nextDouble() * total;
    for (var i = 0; i < pool.length; i++) {
      x -= weights[i];
      if (x <= 0) return pool[i];
    }
    return pool.last;
  }

  /// Ролл итоговой редкости карточки при поимке.
  Rarity rollRarity(AnimalSpecies species) {
    final base = species.baseRarity.stars;
    // Небольшой шанс «повысить» редкость (+1 звезда).
    final bonus = _random.nextDouble() < 0.12 ? 1 : 0;
    return Rarity.fromStars(min(5, base + bonus));
  }

  /// Шанс «блестящей» вариации ~2%.
  bool rollShiny() => _random.nextDouble() < 0.02;
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
