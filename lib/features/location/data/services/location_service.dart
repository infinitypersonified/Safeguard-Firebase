import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safeguard/features/location/data/models/location_model.dart';
import 'location_service_web.dart'
    if (dart.library.io) 'location_service_stub.dart' as web_location;

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionSubscription;
  final StreamController<LocationModel> _locationController =
      StreamController<LocationModel>.broadcast();

  Stream<LocationModel> get locationStream => _locationController.stream;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  Future<bool> checkAndRequestPermission() async {
    if (kIsWeb) return true; // Browser handles permission via its own prompt
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<LocationModel?> getCurrentLocation() async {
    try {
      if (kIsWeb) {
        // Web: use browser geolocation
        return await web_location.getWebLocation();
      }

      // Mobile: use Geolocator
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
        timestamp: position.timestamp,
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      if (!kIsWeb) {
        // Mobile only: try last known position as fallback
        try {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null &&
              !(last.latitude == 37.421998 && last.longitude == -122.084000)) {
            return LocationModel(
              latitude: last.latitude,
              longitude: last.longitude,
              accuracy: last.accuracy,
              altitude: last.altitude,
              speed: last.speed,
              heading: last.heading,
              timestamp: last.timestamp,
            );
          }
        } catch (_) {}
      }
      return null;
    }
  }

  Future<bool> startTracking() async {
    if (_isTracking) return true;

    if (kIsWeb) {
      // Web: get once and add to stream
      final loc = await getCurrentLocation();
      if (loc != null) _locationController.add(loc);
      _isTracking = true;
      return true;
    }

    // Mobile: continuous GPS stream
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return false;

    _isTracking = true;
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position position) {
        final location = LocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          altitude: position.altitude,
          speed: position.speed,
          heading: position.heading,
          timestamp: position.timestamp,
        );
        _locationController.add(location);
      },
      onError: (error) => debugPrint('Location tracking error: $error'),
    );

    return true;
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
  }

  double calculateDistance(
      double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  Future<bool> isLocationServiceEnabled() async {
    if (kIsWeb) return true;
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<void> openLocationSettings() async {
    if (kIsWeb) return;
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    if (kIsWeb) return;
    await Geolocator.openAppSettings();
  }

  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
