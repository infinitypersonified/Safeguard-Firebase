import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeguard/core/theme/app_theme.dart';
import 'package:safeguard/core/widgets/glassmorphic_container.dart';
import 'package:safeguard/features/auth/presentation/providers/auth_provider.dart';
import 'package:safeguard/features/sos/presentation/providers/sos_provider.dart';
import 'package:safeguard/features/location/presentation/providers/location_provider.dart';

class SOSScreen extends ConsumerStatefulWidget {
  const SOSScreen({super.key});

  @override
  ConsumerState<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends ConsumerState<SOSScreen> {
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  void _startCooldownTimer() {
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final sosNotifier = ref.read(sosProvider.notifier);
      sosNotifier.updateCooldown();
      setState(() {
        _cooldownSeconds = sosNotifier.canSendAlert()
            ? 0
            : ref.read(sosProvider).remainingCooldown;
      });
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleSOS() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final sosNotifier = ref.read(sosProvider.notifier);
    if (!sosNotifier.canSendAlert()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait before sending another alert'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final locationNotifier = ref.read(locationProvider.notifier);
    final location = await locationNotifier.getCurrentLocation();

    if (!mounted) return;

    if (location == null) {
      await _showLocationErrorDialog();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error),
            SizedBox(width: 8),
            Text('Confirm SOS'),
          ],
        ),
        content: const Text(
          'This will send your current location and details to all administrators. '
          'Only use this in genuine emergencies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await sosNotifier.sendSOSAlert(
        userId: user.id,
        userName: user.fullName,
        userEmail: user.email,
        matricNumber: user.matricNumber,
        phoneNumber: user.phoneNumber,
        latitude: location.latitude,
        longitude: location.longitude,
        // Health fields
        bloodType: user.bloodType,
        allergies: user.allergies,
        ongoingSickness: user.ongoingSickness,
        genotype: user.genotype,
        priorIllness: user.priorIllness,
        chronicConditions: user.chronicConditions,
        currentMedications: user.currentMedications,
        age: user.age,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('SOS Alert sent! Help is on the way.'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final error = ref.read(sosProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to send SOS'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showLocationErrorDialog() async {
    final locationNotifier = ref.read(locationProvider.notifier);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_searching,
            color: AppColors.warning, size: 48),
        title: const Text('Location Error'),
        content: const Text(
          'Unable to get your current location. Please check:\n\n'
          '• Location services are enabled\n'
          '• GPS is turned on\n'
          '• Location permission is granted',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              locationNotifier.openSettings();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosProvider);
    final locationState = ref.watch(locationProvider);

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Emergency SOS',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Send an emergency alert to get help',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.grey400
                            : AppColors.grey500,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Center(
                  child: GestureDetector(
                    onTap: sosState.isSendingAlert || _cooldownSeconds > 0
                        ? null
                        : _handleSOS,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [AppColors.error, AppColors.errorDark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: sosState.isSendingAlert
                            ? const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 4)
                            : _cooldownSeconds > 0
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.timer,
                                          color: Colors.white, size: 50),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_cooldownSeconds}s',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.emergency,
                                          color: Colors.white, size: 60),
                                      SizedBox(height: 8),
                                      Text(
                                        'SOS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                GlassmorphicContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: locationState.currentLocation != null
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Location Status',
                                    style:
                                        Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text(
                                  locationState.currentLocation != null
                                      ? 'Location detected'
                                      : 'Waiting for location...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.grey400
                                            : AppColors.grey500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (locationState.currentLocation != null)
                            const Text('✓',
                                style: TextStyle(
                                    color: AppColors.success, fontSize: 20)),
                        ],
                      ),
                      if (locationState.currentLocation != null) ...[
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.my_location,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                locationState
                                    .currentLocation!.formattedCoordinates,
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
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GlassmorphicContainer(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.error.withValues(alpha: 0.1),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Important',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: AppColors.error),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem(
                          '1', 'Tap the SOS button in case of emergency'),
                      const SizedBox(height: 8),
                      _buildInfoItem(
                          '2', 'Your location will be sent to administrators'),
                      const SizedBox(height: 8),
                      _buildInfoItem(
                          '3', 'Stay calm and wait for help to arrive'),
                      const SizedBox(height: 8),
                      _buildInfoItem(
                          '4', 'You can cancel within the cooldown period'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
