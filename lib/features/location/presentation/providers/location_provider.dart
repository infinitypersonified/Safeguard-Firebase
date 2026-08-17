import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeguard/features/location/data/models/location_model.dart';
import 'package:safeguard/features/location/data/services/location_service.dart';

// Service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// Location state
class LocationState {
  final LocationModel? currentLocation;
  final bool isTracking;
  final bool hasPermission;
  final String? error;

  LocationState({
    this.currentLocation,
    this.isTracking = false,
    this.hasPermission = false,
    this.error,
  });

  LocationState copyWith({
    LocationModel? currentLocation,
    bool? isTracking,
    bool? hasPermission,
    String? error,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      isTracking: isTracking ?? this.isTracking,
      hasPermission: hasPermission ?? this.hasPermission,
      error: error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _service;

  LocationNotifier(this._service) : super(LocationState());

  /// Check and request location permission
  Future<bool> checkPermission() async {
    final hasPermission = await _service.checkAndRequestPermission();
    state = state.copyWith(hasPermission: hasPermission);
    return hasPermission;
  }

  /// Get current location
  Future<LocationModel?> getCurrentLocation() async {
    try {
      final location = await _service.getCurrentLocation();
      if (location != null) {
        state = state.copyWith(currentLocation: location, error: null);
      }
      return location;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Start tracking location
  Future<void> startTracking() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      state = state.copyWith(error: 'Location permission denied');
      return;
    }

    final started = await _service.startTracking();
    if (started) {
      state = state.copyWith(isTracking: true);
    }
  }

  /// Stop tracking location
  void stopTracking() {
    _service.stopTracking();
    state = state.copyWith(isTracking: false);
  }

  /// Open location settings
  Future<void> openSettings() async {
    await _service.openLocationSettings();
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await _service.openAppSettings();
  }
}

// Provider
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationNotifier(service);
});

// Convenience providers
final currentLocationProvider = Provider<LocationModel?>((ref) {
  return ref.watch(locationProvider).currentLocation;
});

final isLocationTrackingProvider = Provider<bool>((ref) {
  return ref.watch(locationProvider).isTracking;
});
