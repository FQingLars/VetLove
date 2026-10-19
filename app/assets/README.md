# Каталоги ассетов

Объявлены в `app/pubspec.yaml`:

```yaml
assets:
  - assets/animals/
  - assets/cards/
```

Сейчас в них лежат только `.gitkeep` — реальных изображений нет.

## Что нужно положить сюда

- `animals/` — иллюстрации видов. Пути уже прописаны в
  `lib/data/species_catalog.dart`, например
  `assets/animals/vulpes_vulpes.png`, `assets/animals/lynx_lynx.png`.
  Без файлов приложение не сломается: `CollectionCardWidget` и
  `CardDetailsScreen` проверяют существование файла и рисуют заглушку
  с иконкой по таксону.
- `cards/` — дополнительные изображения карточек (рамки, блики, «блестящие»
  вариации).

Каталоги нельзя удалять, пока они объявлены в `pubspec.yaml`: сборка упадёт
с `no file or variants found for asset`. Если контент так и не появится,
уберите строки `assets:` из pubspec — код продолжит работать на заглушках.
