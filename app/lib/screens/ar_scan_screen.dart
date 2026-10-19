import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/animal_species.dart';
import '../providers/collection_provider.dart';
import '../services/animal_recognition_service.dart';
import '../services/location_service.dart';
import '../widgets/rarity_widgets.dart';

/// AR-экран: живой вид с камеры, рамки распознавания, кнопка «поймать».
class ArScanScreen extends StatefulWidget {
  const ArScanScreen({super.key});

  @override
  State<ArScanScreen> createState() => _ArScanScreenState();
}

class _ArScanScreenState extends State<ArScanScreen> {
  // Распознавание идёт через iNaturalist Vision API (серверная ML-модель);
  // при отсутствии сети — офлайн-фолбэк локальным спавном по региону.
  final _recognition = AnimalRecognitionService();
  List<DetectionResult> _detections = [];
  bool _scanning = false;
  String _region = 'forest';
  double _lat = 0, _lon = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _resolveLocation();
      _startScan();
    });
  }

  Future<void> _resolveLocation() async {
    // В проде — позиция из LocationService (geolocator).
    final pos = await LocationService().getCurrent();
    if (pos != null && mounted) {
      setState(() {
        _lat = pos.latitude;
        _lon = pos.longitude;
        _region = LocationService().regionFor(_lat, _lon);
      });
    }
  }

  Future<void> _startScan() async {
    setState(() => _scanning = true);
    // В проде здесь: CameraController + ImageAnalysis listener -> detect(frame).
    // В проде кадр берётся из CameraController.getImage(jpgQuality: 80).
    final frame = Uint8List.fromList(List.generate(1024, (i) => i % 256));
    final res = await _recognition.detect(frame, _region, lat: _lat, lon: _lon);
    if (!mounted) return;
    setState(() {
      _detections = res.take(3).toList();
      _scanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AR-поиск'),
        actions: [
          IconButton(onPressed: _startScan, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Камера: в проде — CameraPreview(controller). Здесь — градиент-заглушка.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF16324F), Color(0xFF0B1D2E)],
              ),
            ),
            child: Center(
              child: Icon(Icons.videocam_off_outlined,
                  color: Colors.white24, size: 96),
            ),
          ),

          // Рамки распознанных животных.
          ..._detections.asMap().entries.map((e) {
            final d = e.value;
            return Positioned(
              left: d.box.left * MediaQuery.of(context).size.width,
              top: d.box.top * MediaQuery.of(context).size.height,
              width: d.box.width * MediaQuery.of(context).size.width,
              height: d.box.height * MediaQuery.of(context).size.height,
              child: _DetectionBox(detection: d),
            );
          }),

          if (_scanning)
            const Center(child: CircularProgressIndicator()),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Регион: $_region • найдено: ${_detections.length}'
                    '${_detections.any((d) => d.fromApi) ? ' • iNaturalist' : ' • офлайн'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed:
                        _detections.isEmpty || _scanning ? null : _captureFirst,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Поймать первое'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _captureFirst() {
    final d = _detections.first;
    final rarity = _recognition.rollRarity(d.species);
    final shiny = _recognition.rollShiny();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CaptureSheet(
        species: d.species,
        rarity: rarity,
        shiny: shiny,
        confidence: d.confidence,
        lat: _lat,
        lon: _lon,
        fromApi: d.fromApi,
      ),
    );
  }
}

class _DetectionBox extends StatelessWidget {
  const _DetectionBox({required this.detection});

  final DetectionResult detection;

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(detection.species.baseRarity);
    return Stack(
      children: [
        IgnorePointer(
          child: CustomPaint(
            painter: _BoxPainter(color: color),
            size: Size.infinite,
          ),
        ),
        Positioned(
          top: -26,
          left: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6)),
            child: Text(
              '${detection.species.nameRu} ${(detection.confidence * 100).round()}%',
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _BoxPainter extends CustomPainter {
  _BoxPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const corner = 24.0;
    final r = Offset(size.width, size.height);
    // Углы рамки в стиле сканера.
    canvas.drawPath(
        Path()
          ..moveTo(0, corner)
          ..lineTo(0, 0)
          ..lineTo(corner, 0),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(r.dx - corner, 0)
          ..lineTo(r.dx, 0)
          ..lineTo(r.dx, corner),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(0, r.dy - corner)
          ..lineTo(0, r.dy)
          ..lineTo(corner, r.dy),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(r.dx - corner, r.dy)
          ..lineTo(r.dx, r.dy)
          ..lineTo(r.dx, r.dy - corner),
        p);
  }

  @override
  bool shouldRepaint(covariant _BoxPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Лист подтверждения поимки: показывает карточку и редкость до сохранения.
class _CaptureSheet extends StatelessWidget {
  const _CaptureSheet({
    required this.species,
    required this.rarity,
    required this.shiny,
    required this.confidence,
    required this.lat,
    required this.lon,
    this.fromApi = false,
  });

  final AnimalSpecies species;
  final Rarity rarity;
  final bool shiny;
  final double confidence;
  final bool fromApi;
  final double lat;
  final double lon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Найдено: ${species.nameRu}',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              if (shiny)
                const Icon(Icons.auto_awesome, color: Colors.amber),
            ],
          ),
          const SizedBox(height: 8),
          Text('Уверенность ${fromApi ? 'iNaturalist API' : 'локальной модели'}: '
              '${(confidence * 100).round()}%'),
          const SizedBox(height: 8),
          RarityBadge(rarity: rarity),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final ctx = context;
                final lat = this.lat, lon = this.lon;
                Navigator.pop(context);
                await ctx.read<CollectionProvider>().capture(
                      species: species,
                      rarity: rarity,
                      lat: lat,
                      lon: lon,
                      isShiny: shiny,
                    );
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text('В коллекцию: ${species.nameRu} • '
                        '${rarity.labelRu} (${rarity.stars}★)'
                        '${shiny ? ' ✨' : ''}'),
                  ));
                }
              },
              icon: const Icon(Icons.favorite),
              label: const Text('В коллекцию!'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отпустить'),
          ),
        ],
      ),
    );
  }
}
