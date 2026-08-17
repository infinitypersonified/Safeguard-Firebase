import 'package:safeguard/features/location/data/models/location_model.dart';

/// Stub for non-web platforms.
/// On mobile, location_service.dart uses Geolocator directly
/// so this function is never actually called.
Future<LocationModel?> getWebLocation() async => null;
