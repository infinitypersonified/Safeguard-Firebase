import 'package:geolocator/geolocator.dart';
import 'package:safeguard/features/location/data/models/location_model.dart';

Future<LocationModel?> getWebLocation() async {
  try {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition();

    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      heading: position.heading,
      timestamp: DateTime.now(),
    );
  } catch (e) {
    return null;
  }
}
