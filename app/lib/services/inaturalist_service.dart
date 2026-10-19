import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Клиент публичного REST API iNaturalist (https://api.inaturalist.org).
///
/// Использует vision-модель классификации видов на стороне сервера —
/// в мобильном приложении не нужно держать и дообучать собственную
/// ML-модель (TFLite), что снимает проблему производительности и размера APK.
///
/// Аутентификация опциональна: без ключа действуют пониженные rate-limit'ы
/// (1000 запросов/час на IP). Ключ приложения задаётся через [apiKey]
/// (см. https://www.inaturalist.org/oauth/applications/new).
class InaturalistService {
  InaturalistService({
    Dio? dio,
    this.apiKey,
    String baseUrl = 'https://api.inaturalist.org/v1',
  }) : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: {
                if (apiKey?.isNotEmpty ?? false)
                  'X-Vision-Client-Id': apiKey,
              },
            ));

  final Dio _dio;

  /// Клиентский ID приложения iNaturalist (optional, повышает лимиты).
  final String? apiKey;

  /// Результат score-запроса: распознанный таксон с уверенностью модели.
  ScoreCandidate? _lastScore;

  ScoreCandidate? get lastScore => _lastScore;

  /// Распознать животное на изображении (JPEG/PNG bytes).
  ///
  /// Возвращает список кандидатов (top-K по composite-уверенности).
  /// [lat]/[lon] повышают точность: модель iNat использует гео-приор
  /// («что может жить в этой точке»).
  Future<List<ScoreCandidate>> scoreImage(
    Uint8List imageBytes, {
    double? lat,
    double? lon,
    int taxonId = 1 /* Animalia */,
  }) async {
    final form = FormData.fromMap({
      'images': MultipartFile.fromBytes(imageBytes, filename: 'frame.jpg'),
      'taxon_id': taxonId,
      if (lat != null && lon != null) 'lat': lat.toString(),
      if (lat != null && lon != null) 'lon': lon.toString(),
      'obs_year': DateTime.now().year,
    });

    final resp = await _dio.post('/vision/score', data: form);
    final data = resp.data as Map<String, dynamic>;
    final scores = (data['scores'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(ScoreCandidate.fromJson)
        .toList()
      ..sort((a, b) => b.compositeScore.compareTo(a.compositeScore));
    _lastScore = scores.isEmpty ? null : scores.first;
    return scores;
  }

  /// Поиск таксона по латинскому названию → id для маппинга на локальный
  /// каталог видов (кэшируется в памяти).
  Future<int?> lookupTaxonId(String scientificName) async {
    if (_taxonCache.containsKey(scientificName)) {
      return _taxonCache[scientificName];
    }
    try {
      final resp = await _dio.get('/taxa', queryParameters: {
        'q': scientificName,
        'rank': 'species',
        'per_page': 5,
      });
      final results = (resp.data['results'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final exact = results.where(
          (r) => (r['name'] as String? ?? '').toLowerCase() == scientificName.toLowerCase());
      final hit = (exact.isNotEmpty ? exact.first : results.firstOrNull);
      final id = hit == null ? null : (hit['id'] as num?)?.toInt();
      _taxonCache[scientificName] = id;
      return id;
    } on DioException {
      _taxonCache[scientificName] = null;
      return null;
    }
  }

  final Map<String, int?> _taxonCache = {};
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Один кандидат распознавания из ответа `/vision/score`.
class ScoreCandidate {
  const ScoreCandidate({
    required this.taxonId,
    required this.scientificName,
    required this.commonName,
    required this.compositeScore,
    required this.visionScore,
    this.rank,
    this.imageUrl,
  });

  final int taxonId;
  final String scientificName;
  final String commonName;

  /// Итоговая уверенность 0..1 (vision-скор × гео-приор).
  final double compositeScore;

  /// «Чисто визуальная» уверенность без учёта геометки.
  final double visionScore;

  /// Таксономический ранг (`species`, `genus` …).
  final String? rank;

  /// Превью-фото таксона из iNat.
  final String? imageUrl;

  factory ScoreCandidate.fromJson(Map<String, dynamic> j) {
    final t = j['taxon'] as Map<String, dynamic>? ?? {};
    final defaultPhoto = (t['default_photo'] as Map<String, dynamic>? ?? {})['square_url'] as String?;
    return ScoreCandidate(
      taxonId: (t['id'] as num).toInt(),
      scientificName: t['name'] as String? ?? '',
      commonName: t['preferred_common_name'] as String? ?? '',
      compositeScore: (j['composite_score'] as num? ?? 0).toDouble(),
      visionScore: (j['vision_score'] as num? ?? 0).toDouble(),
      rank: t['rank'] as String?,
      imageUrl: defaultPhoto,
    );
  }
}
