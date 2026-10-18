import '../models/animal_species.dart';

/// Локальная энциклопедия видов (в проде синхронизируется с бэкендом).
class SpeciesCatalog {
  static final List<AnimalSpecies> all = [
    const AnimalSpecies(
      speciesId: 'vulpes_vulpes',
      nameRu: 'Лисица рыжая',
      scientificName: 'Vulpes vulpes',
      taxonomy: 'Млекопитающие, псовые',
      habitat: 'Евразия и Северная Америка: леса, поля, окраины городов',
      description:
          'Самый распространённый вид диких псовых. Хитрый и адаптивный хищник, '
          'известна своим рыжим окрас и пышный хвост-«меховку». Роет сложные норы — «послёдищи».',
      diet: 'Грызуны, птицы, насекомые, ягоды',
      lifespan: '3–6 лет в дикой природе',
      sizeInfo: 'Длина 60–90 см, масса 5–14 кг',
      iucnStatus: 'LC',
      baseRarityStars: 2,
      imagePath: 'assets/animals/vulpes_vulpes.png',
      regions: ['forest', 'field', 'urban'],
      inaturalistTaxonId: 75162,
    ),
    const AnimalSpecies(
      speciesId: 'lynx_lynx',
      nameRu: 'Рысь евразийская',
      scientificName: 'Lynx lynx',
      taxonomy: 'Млекопитающие, кошачьи',
      habitat: 'Тайга и смешанные леса Евразии',
      description:
          'Крупный скрытный кот с кисточками на ушах и коротким хвостом. '
          'Невозмутимый охотник на зайцев; следы его почти невозможно найти.',
      diet: 'Зайцы, птицы, мелкие копытные',
      lifespan: '12–17 лет',
      sizeInfo: 'Длина 80–130 см, масса 15–35 кг',
      iucnStatus: 'LC',
      baseRarityStars: 4,
      imagePath: 'assets/animals/lynx_lynx.png',
      regions: ['forest', 'mountain'],
      inaturalistTaxonId: 504425,
    ),
    const AnimalSpecies(
      speciesId: 'aries_canadensis',
      nameRu: 'Баран большой (толсторог)',
      scientificName: 'Ovis canadensis',
      taxonomy: 'Млекопитающие, полорогие',
      habitat: 'Горные районы Северной Америки',
      description:
          'Массивные рога самцов весят до 14 кг. Легко лазает по отвесным скалам, '
          'где не достанет ни один хищник.',
      diet: 'Травы, злаки, кустарники',
      lifespan: '10–14 лет',
      sizeInfo: 'Масса 53–143 кг',
      iucnStatus: 'NT',
      baseRarityStars: 3,
      imagePath: 'assets/animals/aries_canadensis.png',
      regions: ['mountain'],
      inaturalistTaxonId: 504429,
    ),
    const AnimalSpecies(
      speciesId: 'struthio_camelus',
      nameRu: 'Страус обыкновенный',
      scientificName: 'Struthio camelus',
      taxonomy: 'Птицы, страусообразные',
      habitat: 'Саванны и полупустыни Африки',
      description:
          'Крупнейшая современная птица, не умеющая летать, но способная '
          'бежать со скоростью до 70 км/ч. Глаз крупнее мозга.',
      diet: 'Растительная пища, насекомые',
      lifespan: '30–40 лет',
      sizeInfo: 'Рост до 2,7 м, масса до 150 кг',
      iucnStatus: 'LC',
      baseRarityStars: 3,
      imagePath: 'assets/animals/struthio_camelus.png',
      regions: ['savanna', 'desert'],
      inaturalistTaxonId: 21163,
    ),
    const AnimalSpecies(
      speciesId: 'ailuropoda_melanoleuca',
      nameRu: 'Панда большая',
      scientificName: 'Ailuropoda melanoleuca',
      taxonomy: 'Млекопитающие, медвежьи',
      habitat: 'Бамбуковые леса горного Китая',
      description:
          'Символ охраны природы. Поедает до 12 кг бамбука в сутки, '
          'хотя пищеварение у неё «хищное». Одиночка.',
      diet: 'Бамбук (99% рациона)',
      lifespan: '20–30 лет',
      sizeInfo: 'Длина 1,2–1,8 м, масса 75–135 кг',
      iucnStatus: 'VU',
      baseRarityStars: 5,
      imagePath: 'assets/animals/ailuropoda_melanoleuca.png',
      regions: ['bamboo_forest'],
      inaturalistTaxonId: 504428,
    ),
    const AnimalSpecies(
      speciesId: 'ciconia_ciconia',
      nameRu: 'Аист белый',
      scientificName: 'Ciconia ciconia',
      taxonomy: 'Птицы, аистообразные',
      habitat: 'Открытые луга Европы и Азии рядом с жильём человека',
      description:
          'Перелётный гигант с размахом крыльев до 2 м. Гнездится на крышах и '
          'столбах, в народе — вестник весны и уюта.',
      diet: 'Лягушки, мелкие грызуны, насекомые',
      lifespan: 'до 20 лет (по кольцеваниям)',
      sizeInfo: 'Рост ~1 м, масса 3–4,5 кг',
      iucnStatus: 'LC',
      baseRarityStars: 2,
      imagePath: 'assets/animals/ciconia_ciconia.png',
      regions: ['field', 'wetland', 'urban'],
      inaturalistTaxonId: 504427,
    ),
    const AnimalSpecies(
      speciesId: 'panthera_onca',
      nameRu: 'Ягуар',
      scientificName: 'Panthera onca',
      taxonomy: 'Млекопитающие, кошачьи',
      habitat: 'Пампасы, тропические леса и болота Латинской Америки',
      description:
          'Крупнейшая кошка Америки с сильнейшим укусом среди всех современных '
          'хищников относительно размера. Убивает добычу прокусывая череп.',
      diet: 'Капибары, рыба, черепахи, оленевидные',
      lifespan: '12–15 лет',
      sizeInfo: 'Масса 35–110 кг',
      iucnStatus: 'NT',
      baseRarityStars: 5,
      imagePath: 'assets/animals/panthera_onca.png',
      regions: ['jungle', 'wetland'],
      inaturalistTaxonId: 504426,
    ),
    const AnimalSpecies(
      speciesId: 'penguin_galapagoi',
      nameRu: 'Пингвин Гумбольдта',
      scientificName: 'Spheniscus humboldti',
      taxonomy: 'Птицы, пингвиновые',
      habitat: 'Побережья Чили и Перу (течение Гумбольдта)',
      description:
          'Тёпловодный пингвин, живущий у берегов Южной Америки. '
          'Насиживает яйца в норах, чтобы спастись от жары.',
      diet: 'Анчоусы, сардины',
      lifespan: '15–20 лет',
      sizeInfo: 'Рост 50–65 см, масса ~3,6 кг',
      iucnStatus: 'VU',
      baseRarityStars: 4,
      imagePath: 'assets/animals/penguin_galapagoi.png',
      regions: ['coast'],
      inaturalistTaxonId: 504424,
    ),
    const AnimalSpecies(
      speciesId: 'lepidochelys_coreacea',
      nameRu: 'Кожистая черепаха',
      scientificName: 'Dermochelys coriacea',
      taxonomy: 'Пресмыкающиеся, черепахи',
      habitat: 'Все океаны; гнездится на тропических пляжах',
      description:
          'Самая крупная черепаха планеты и пресмыкающееся вообще после крокодилов. '
          'Ныряет на 1200 м и держится под водой больше часа.',
      diet: 'Медузы',
      lifespan: 'оценивается в 45+ лет',
      sizeInfo: 'Длина панциря до 2 м, масса до 700 кг',
      iucnStatus: 'VU',
      baseRarityStars: 5,
      imagePath: 'assets/animals/lepidochelys_coreacea.png',
      regions: ['ocean', 'beach'],
      inaturalistTaxonId: 504423,
    ),
    const AnimalSpecies(
      speciesId: 'tursiops_truncatus',
      nameRu: 'Дельфин-бутылконос',
      scientificName: 'Tursiops truncatus',
      taxonomy: 'Млекопитающие, китообразные',
      habitat: 'Тёплые и умеренные воды всех океанов',
      description:
          'Высокоинтеллектуальный социальный кит. Узнаёт себя в зеркале, '
          'общается свистами-«именами» и охотится сообща, загоняя рыбу.',
      diet: 'Рыба, кальмары',
      lifespan: '40–50 лет',
      sizeInfo: 'Длина 2–4 м, масса 150–650 кг',
      iucnStatus: 'LC',
      baseRarityStars: 3,
      imagePath: 'assets/animals/tursiops_truncatus.png',
      regions: ['ocean', 'coast'],
      inaturalistTaxonId: 504422,
    ),
    const AnimalSpecies(
      speciesId: 'capra_hircus',
      nameRu: 'Коза домашняя',
      scientificName: 'Capra hircus',
      taxonomy: 'Млекопитающие, полорогие',
      habitat: 'По всему миру; происхождение — горный Загрос',
      description:
          'Одно из древнейших одомашненных животных. Отличная балансировка и '
          'любопытство позволяют ей залезть практически куда угодно.',
      diet: 'Трава, листва, зерно',
      lifespan: '12–18 лет',
      sizeInfo: 'Рост 40–100 см, масса 25–100 кг',
      iucnStatus: 'LC',
      baseRarityStars: 1,
      imagePath: 'assets/animals/capra_hircus.png',
      regions: ['farm', 'mountain', 'urban'],
      inaturalistTaxonId: 504421,
    ),
    const AnimalSpecies(
      speciesId: 'chinchilla_lanigera',
      nameRu: 'Шиншилла длинношерстная',
      scientificName: 'Chinchilla lanigera',
      taxonomy: 'Млекопитающие, грызуны',
      habitat: 'Анды Чили',
      description:
          'Обладает самым густым мехом среди наземных зверьков — до 60 волосин '
          'на фолликул. Купается в вулканической пыли.',
      diet: 'Травы, кора, семена',
      lifespan: '10–20 лет',
      sizeInfo: 'Длина 22–38 см, масса 400–600 г',
      iucnStatus: 'EN',
      baseRarityStars: 4,
      imagePath: 'assets/animals/chinchilla_lanigera.png',
      regions: ['mountain'],
      inaturalistTaxonId: 504420,
    ),
  ];

  static final Map<String, AnimalSpecies> _byId = {
    for (final s in all) s.speciesId: s,
  };

  static AnimalSpecies byId(String id) =>
      _byId[id] ??
      AnimalSpecies(
        speciesId: id,
        nameRu: id,
        scientificName: '',
        taxonomy: '',
        habitat: '',
        description: '',
        diet: '',
        lifespan: '',
        sizeInfo: '',
        iucnStatus: 'LC',
        baseRarityStars: 1,
        imagePath: '',
      );

  /// Какие виды могут «заспоуниться» в указанном регионе.
  static List<AnimalSpecies> inRegion(String region) =>
      all.where((s) => s.regions.contains(region)).toList();
}
