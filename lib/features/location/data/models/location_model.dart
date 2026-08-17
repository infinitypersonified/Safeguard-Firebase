class LocationModel {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    required this.timestamp,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      altitude: json['altitude']?.toDouble(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Calculate distance between two locations in meters using Haversine formula
  double distanceTo(LocationModel other) {
    const double earthRadius = 6371000; // meters
    final double lat1 = latitude * 0.0174533; // convert to radians
    final double lat2 = other.latitude * 0.0174533;
    final double dLat = (other.latitude - latitude) * 0.0174533;
    final double dLng = (other.longitude - longitude) * 0.0174533;

    final double a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(lat1) * _cos(lat2) * _sin(dLng / 2) * _sin(dLng / 2);
    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadius * c;
  }

  // Simple math functions to avoid dart:math import issues
  double _sin(double x) {
    return _taylorSin(x);
  }

  double _cos(double x) {
    return _taylorSin(x + 1.5708);
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159;
    if (x == 0 && y > 0) return 1.5708;
    if (x == 0 && y < 0) return -1.5708;
    return 0;
  }

  double _atan(double x) {
    // Simplified atan using Taylor series
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * 1.5708 - _atan(1 / x);
    }
    double result = 0;
    double term = x;
    for (int i = 0; i < 10; i++) {
      result += term / (2 * i + 1) * (i % 2 == 0 ? 1 : -1);
      term *= x * x;
    }
    return result;
  }

  double _taylorSin(double x) {
    // Normalize x to [-pi, pi]
    const double pi = 3.14159;
    while (x > pi) { x -= 2 * pi; }
    while (x < -pi) { x += 2 * pi; }

    double result = 0;
    double term = x;
    for (int i = 0; i < 10; i++) {
      result += term;
      term *= -x * x / ((2 * i + 2) * (2 * i + 3));
    }
    return result;
  }

  String get formattedCoordinates {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  bool get isValid => latitude != 0 && longitude != 0;
}
