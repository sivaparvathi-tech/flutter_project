import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

const Map<String, List<double>> cityCoordinates = {
  'brooklyn': [40.6782, -73.9442],
  'srikakulam': [18.2989, 83.8979],
  'vizianagaram': [18.1066, 83.3955],
  'visakhapatnam': [17.6868, 83.2185],
  'ravulapalem': [16.7600, 81.8500],
  'hyderabad': [17.3850, 78.4867],
  'vijayawada': [16.5062, 80.6480],
  'guntur': [16.3067, 80.4365],
  'rajahmundry': [17.0005, 81.8040],
  'kakinada': [16.9891, 82.2475],
  'vizag': [17.6868, 83.2185],
};

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Position? lastPosition;

  Future<bool> getPermission() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  Future<Position?> getCurrentPosition() async {
    final ok = await getPermission();
    if (!ok) return null;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      lastPosition = position;
      return position;
    } catch (_) {
      return null;
    }
  }

  double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double? distanceToCity(String location) {
    final position = lastPosition;
    if (position == null) return null;
    final coords = cityCoordinates[location.trim().toLowerCase()];
    if (coords == null) return null;
    return distanceKm(
      position.latitude,
      position.longitude,
      coords[0],
      coords[1],
    );
  }

  String formatDistanceKm(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  double _toRad(double deg) => deg * math.pi / 180;
}