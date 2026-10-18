import 'dart:math';

import 'package:geolocator/geolocator.dart';

/// Гео-сервис: позиция игрока и определение «региона» для AR-спавна.
class LocationService {
  /// Запросить разрешение и получить текущую позицию.
  Future<Position?> getCurrent() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (_) {
      return null;
    }
  }

  /// Упрощённое определение биома по координатам (в проде — тайловая база
  /// ГИС/Google Places). Детерминированный выбор из широты/долготы.
  String regionFor(double lat, double lon) {
    const regions = [
      'forest', 'field', 'urban', 'mountain', 'wetland',
      'coast', 'savanna', 'desert', 'jungle', 'farm',
    ];
    final idx = ((lat.abs() * 7 + lon.abs() * 13).floor()) % regions.length;
    return regions[idx];
  }

  /// Дистанция между двумя точками, метры (формула гаверсинуса).
  static double distanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const earthR = 6371000.0;
    double rad(double d) => d * pi / 180.0;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a = _sin2(dLat / 2) +
        cos(rad(lat1)) * cos(rad(lat2)) * _sin2(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthR * c;
  }

  static double _sin2(double x) {
    final s = sin(x);
    return s * s;
  }
}
