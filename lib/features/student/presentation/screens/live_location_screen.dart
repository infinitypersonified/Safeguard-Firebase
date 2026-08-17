import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safeguard/core/theme/app_theme.dart';
import 'package:safeguard/core/widgets/glassmorphic_container.dart';
import 'package:safeguard/features/location/presentation/providers/location_provider.dart';

class LiveLocationScreen extends ConsumerStatefulWidget {
  const LiveLocationScreen({super.key});

  @override
  ConsumerState<LiveLocationScreen> createState() =>
      _LiveLocationScreenState();
}

class _LiveLocationScreenState extends ConsumerState<LiveLocationScreen> {
  MapController? _mapController;
  final List<LatLng> _locationPoints = [];
  Timer? _updateTimer;
  
  // MapTiler API Key
  static const String _mapTilerApiKey = '6gyau8l4EnP51EiT7u4A';

  @override
  void initState() {
    super.initState();
    _initLocation();
    _startLocationUpdates();
  }

  void _initLocation() {
    Future.microtask(() {
      ref.read(locationProvider.notifier).getCurrentLocation();
      ref.read(locationProvider.notifier).startTracking();
    });
  }

  void _startLocationUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final location = ref.read(locationProvider).currentLocation;
      if (location != null) {
        final point = LatLng(location.latitude, location.longitude);
        if (!_locationPoints.contains(point)) {
          setState(() {
            _locationPoints.add(point);
            _updatePolyline();
          });
        }
      }
    });
  }

  void _updatePolyline() {
    // Polylines will be updated in the map widget
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final currentLocation = locationState.currentLocation;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBackground
                  : AppColors.grey50,
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurface
                  : AppColors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    GlassmorphicButton(
                      onPressed: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Location',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Real-time GPS tracking',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.grey400
                                          : AppColors.grey500,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: locationState.isTracking
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: locationState.isTracking
                              ? AppColors.success.withValues(alpha: 0.5)
                              : AppColors.warning.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: locationState.isTracking
                                  ? AppColors.success
                                  : AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            locationState.isTracking
                                ? 'Tracking'
                                : 'Inactive',
                            style: TextStyle(
                              color: locationState.isTracking
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Map
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: currentLocation != null
                            ? LatLng(currentLocation.latitude,
                                currentLocation.longitude)
                            : const LatLng(9.0820, 8.6753),
                        initialZoom: 16,
                      ),
                      mapController: _mapController,
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$_mapTilerApiKey',
                          userAgentPackageName: 'com.example.safeguard',
                        ),
                        MarkerLayer(
                          markers: [
                            if (currentLocation != null)
                              Marker(
                                point: LatLng(currentLocation.latitude,
                                    currentLocation.longitude),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: AppColors.primary,
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _locationPoints,
                              color: AppColors.primary.withValues(alpha: 0.7),
                              strokeWidth: 4,
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Map Controls
                    Positioned(
                      right: 16,
                      bottom: 100,
                      child: Column(
                        children: [
                          GlassmorphicButton(
                            onPressed: () {
                              _mapController?.move(
                                _mapController!.camera.center,
                                _mapController!.camera.zoom + 1,
                              );
                            },
                            padding: const EdgeInsets.all(12),
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(height: 8),
                          GlassmorphicButton(
                            onPressed: () {
                              _mapController?.move(
                                _mapController!.camera.center,
                                _mapController!.camera.zoom - 1,
                              );
                            },
                            padding: const EdgeInsets.all(12),
                            child: const Icon(Icons.remove),
                          ),
                          const SizedBox(height: 8),
                          GlassmorphicButton(
                            onPressed: () {
                              if (currentLocation != null) {
                                _mapController?.move(
                                  LatLng(currentLocation.latitude,
                                      currentLocation.longitude),
                                  16,
                                );
                              }
                            },
                            padding: const EdgeInsets.all(12),
                            child: const Icon(Icons.my_location),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Location Info Panel
              if (currentLocation != null)
                GlassmorphicContainer(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Location',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentLocation.formattedCoordinates,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontFamily: 'monospace',
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.grey400
                                            : AppColors.grey500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Accuracy',
                              '${currentLocation.accuracy?.toStringAsFixed(0) ?? 'N/A'}m',
                              Icons.gps_fixed,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Altitude',
                              '${currentLocation.altitude?.toStringAsFixed(0) ?? 'N/A'}m',
                              Icons.terrain,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Speed',
                              '${currentLocation.speed?.toStringAsFixed(1) ?? '0'}m/s',
                              Icons.speed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.grey500
                    : AppColors.grey400,
              ),
        ),
      ],
    );
  }
}
