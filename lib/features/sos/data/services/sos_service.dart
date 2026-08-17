import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:safeguard/core/utils/firebase_helper.dart';
import 'package:safeguard/features/location/data/services/location_service.dart';
import 'package:safeguard/features/sos/data/models/sos_alert_model.dart';

class SOSService {
  static final SOSService _instance = SOSService._internal();
  factory SOSService() => _instance;
  SOSService._internal();

  final LocationService _locationService = LocationService();
  final _uuid = const Uuid();

  DateTime? _lastAlertTime;
  bool _isSendingAlert = false;

  bool canSendAlert() {
    if (_lastAlertTime == null) return true;
    return DateTime.now().difference(_lastAlertTime!).inSeconds >= 30;
  }

  int getRemainingCooldown() {
    if (_lastAlertTime == null) return 0;
    final remaining =
        30 - DateTime.now().difference(_lastAlertTime!).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  Future<SOSAlertModel?> sendSOSAlert({
    required String userId,
    String? userName,
    String? userEmail,
    String? matricNumber,
    String? phoneNumber,
    String? bloodType,
    String? allergies,
    String? ongoingSickness,
    String? genotype,
    String? priorIllness,
    String? chronicConditions,
    String? currentMedications,
    int? age,
    String? address,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    if (_isSendingAlert) return null;
    if (!canSendAlert()) return null;

    _isSendingAlert = true;

    try {
      double? lat = latitude;
      double? lng = longitude;

      if (lat == null || lng == null) {
        final location = await _locationService.getCurrentLocation();
        if (location == null) throw Exception('LOCATION_PERMISSION_DENIED');
        lat = location.latitude;
        lng = location.longitude;
      }

      final alertId = _uuid.v4();

      final insertMap = <String, dynamic>{
        'id': alertId,
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'matric_number': matricNumber,
        'phone_number': phoneNumber,
        'latitude': lat,
        'longitude': lng,
        'status': 'pending',
        'blood_type': bloodType,
        'allergies': allergies,
        'ongoing_sickness': ongoingSickness,
        'genotype': genotype,
        'prior_illness': priorIllness,
        'chronic_conditions': chronicConditions,
        'current_medications': currentMedications,
        'age': age,
        'notes': notes,
        'address': address,
      };

      insertMap.removeWhere((key, value) => value == null);

      await FirebaseHelper.createSOSAlert(insertMap);
      await FirebaseHelper.updateLocation(userId, {
        'latitude': lat,
        'longitude': lng,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final alert = SOSAlertModel(
        id: alertId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        matricNumber: matricNumber,
        phoneNumber: phoneNumber,
        latitude: lat,
        longitude: lng,
        status: 'pending',
        createdAt: DateTime.now(),
        bloodType: bloodType,
        allergies: allergies,
        ongoingSickness: ongoingSickness,
        genotype: genotype,
        priorIllness: priorIllness,
        chronicConditions: chronicConditions,
        currentMedications: currentMedications,
        age: age,
      );

      await _createAdminNotifications(alert);
      _lastAlertTime = DateTime.now();
      return alert;
    } catch (e) {
      debugPrint('SOS Error: $e');
      rethrow;
    } finally {
      _isSendingAlert = false;
    }
  }

  Future<void> _createAdminNotifications(SOSAlertModel alert) async {
    try {
      final admins = await FirebaseHelper.getAdminIds();
      for (final admin in admins) {
        await FirebaseHelper.createNotification({
          'user_id': admin['id'],
          'title': '🚨 SOS Alert',
          'body':
              '${alert.userName ?? 'Unknown'} has sent an emergency alert'
              '${alert.matricNumber != null ? ' (${alert.matricNumber})' : ''}',
          'type': 'sos_alert',
          'is_read': false,
          'data': {
            'alert_id': alert.id,
            'user_id': alert.userId,
          },
        });
      }
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  Stream<List<SOSAlertModel>> watchAlerts() {
    return FirebaseHelper.watchSOSAlerts().map(
      (alerts) =>
          alerts.map((alert) => SOSAlertModel.fromJson(alert)).toList(),
    );
  }

  Future<List<SOSAlertModel>> getAllAlerts() async {
    final alerts = await FirebaseHelper.getAllAlerts();
    return alerts.map((alert) => SOSAlertModel.fromJson(alert)).toList();
  }

  Future<List<SOSAlertModel>> getAlertHistory() async {
    final alerts = await FirebaseHelper.getAlertHistory();
    return alerts.map((alert) => SOSAlertModel.fromJson(alert)).toList();
  }

  Future<bool> updateAlertStatus(String alertId, String status) async {
    try {
      await FirebaseHelper.updateAlertStatus(alertId, status);
      return true;
    } catch (e) {
      debugPrint('Error updating alert status: $e');
      return false;
    }
  }

  Future<int> getPendingAlertsCount() async {
    return await FirebaseHelper.getUnreadAlertCount();
  }

  void dispose() {}
}
