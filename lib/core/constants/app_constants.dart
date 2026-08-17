class AppConstants {
  // App Info
  static const String appName = 'Safeguard';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';

  // Location Settings
  static const int locationUpdateInterval = 10;
  static const double locationDistanceFilter = 10;
  static const int locationTimeout = 15;

  // SOS Settings
  static const int sosCooldownSeconds = 30;
  static const int sosRadius = 500;

  // Notification Settings
  static const String notificationChannelId = 'sos_alerts';
  static const String notificationChannelName = 'SOS Alerts';
  static const String notificationChannelDescription =
      'Emergency SOS alerts from students';

  // Map Settings
  static const double defaultMapZoom = 16.0;
  static const double defaultLat = 9.0820;
  static const double defaultLng = 8.6753;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Validation
  static const int minPasswordLength = 8;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int phoneMinLength = 10;
  static const int phoneMaxLength = 15;
  static const int matricMinLength = 5;
  static const int matricMaxLength = 15;
}
