import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeguard/features/sos/data/models/sos_alert_model.dart';
import 'package:safeguard/features/sos/data/services/sos_service.dart';

// Service provider
final sosServiceProvider = Provider<SOSService>((ref) {
  return SOSService();
});

// SOS state
class SOSState {
  final List<SOSAlertModel> alerts;
  final bool isSendingAlert;
  final SOSAlertModel? lastAlert;
  final String? error;
  final int remainingCooldown;

  SOSState({
    this.alerts = const [],
    this.isSendingAlert = false,
    this.lastAlert,
    this.error,
    this.remainingCooldown = 0,
  });

  SOSState copyWith({
    List<SOSAlertModel>? alerts,
    bool? isSendingAlert,
    SOSAlertModel? lastAlert,
    String? error,
    int? remainingCooldown,
  }) {
    return SOSState(
      alerts: alerts ?? this.alerts,
      isSendingAlert: isSendingAlert ?? this.isSendingAlert,
      lastAlert: lastAlert ?? this.lastAlert,
      error: error,
      remainingCooldown: remainingCooldown ?? this.remainingCooldown,
    );
  }
}

class SOSNotifier extends StateNotifier<SOSState> {
  final SOSService _service;

  SOSNotifier(this._service) : super(SOSState()) {
    _init();
  }

  void _init() {
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await _service.getAllAlerts();
      state = state.copyWith(alerts: alerts);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refreshAlerts() async {
    await _loadAlerts();
  }

  /// ✅ FIXED METHOD WITH NEW PARAMS
  Future<bool> sendSOSAlert({
    required String userId,
    String? userName,
    String? userEmail,
    String? matricNumber,
    String? phoneNumber,
    String? bloodType,
    String? allergies,
    String? ongoingSickness,
    double? latitude,
    double? longitude,
  }) async {
    if (state.isSendingAlert) return false;

    if (!_service.canSendAlert()) {
      state = state.copyWith(
        remainingCooldown: _service.getRemainingCooldown(),
        error: 'Please wait before sending another alert',
      );
      return false;
    }

    state = state.copyWith(isSendingAlert: true, error: null);

    try {
      final alert = await _service.sendSOSAlert(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        matricNumber: matricNumber,
        phoneNumber: phoneNumber,
        bloodType: bloodType,
        allergies: allergies,
        ongoingSickness: ongoingSickness,
        latitude: latitude,
        longitude: longitude,
      );

      if (alert != null) {
        state = state.copyWith(
          isSendingAlert: false,
          lastAlert: alert,
        );
        await _loadAlerts();
        return true;
      } else {
        state = state.copyWith(
          isSendingAlert: false,
          error: 'Failed to send alert. Please check location permissions.',
        );
        return false;
      }
    } catch (e) {
      final errorMessage = e.toString();

      if (errorMessage.contains('LOCATION_PERMISSION_DENIED') ||
          errorMessage.contains('location') ||
          errorMessage.contains('permission')) {
        state = state.copyWith(
          isSendingAlert: false,
          error:
              'Location permission is required. Please enable location services.',
        );
      } else {
        state = state.copyWith(
          isSendingAlert: false,
          error: 'Failed to send SOS alert. Please try again.',
        );
      }
      return false;
    }
  }

  Future<bool> updateAlertStatus(String alertId, String status) async {
    try {
      final success = await _service.updateAlertStatus(alertId, status);
      if (success) {
        await _loadAlerts();
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<int> getPendingCount() async {
    return await _service.getPendingAlertsCount();
  }

  void updateCooldown() {
    if (_service.canSendAlert()) {
      state = state.copyWith(remainingCooldown: 0);
    } else {
      state = state.copyWith(
        remainingCooldown: _service.getRemainingCooldown(),
      );
    }
  }

  bool canSendAlert() => _service.canSendAlert();

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// provider
final sosProvider = StateNotifierProvider<SOSNotifier, SOSState>((ref) {
  final service = ref.watch(sosServiceProvider);
  return SOSNotifier(service);
});

// Convenience providers
final pendingAlertsProvider = Provider<List<SOSAlertModel>>((ref) {
  return ref.watch(sosProvider).alerts.where((a) => a.isPending).toList();
});

final resolvedAlertsProvider = Provider<List<SOSAlertModel>>((ref) {
  return ref.watch(sosProvider).alerts.where((a) => a.isResolved).toList();
});

final pendingCountProvider = Provider<int>((ref) {
  return ref.watch(sosProvider).alerts.where((a) => a.isPending).length;
});

final isSendingAlertProvider = Provider<bool>((ref) {
  return ref.watch(sosProvider).isSendingAlert;
});