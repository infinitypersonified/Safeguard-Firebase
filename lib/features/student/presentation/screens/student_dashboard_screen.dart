import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeguard/core/theme/app_theme.dart';
import 'package:safeguard/core/widgets/animated_button.dart';
import 'package:safeguard/core/widgets/glassmorphic_container.dart';
import 'package:safeguard/features/auth/presentation/providers/auth_provider.dart';
import 'package:safeguard/features/auth/presentation/screens/login_screen.dart';
import 'package:safeguard/features/location/presentation/providers/location_provider.dart';
import 'package:safeguard/features/sos/presentation/providers/sos_provider.dart';
import 'package:safeguard/features/sos/presentation/screens/sos_screen.dart';
import 'package:safeguard/features/student/presentation/screens/profile_screen.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  int _currentIndex = 0;
  Timer? _cooldownTimer;

  // Track which tabs have been visited to avoid rebuilding
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    // Delay location init so it doesn't block the first frame
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ref.read(locationProvider.notifier).getCurrentLocation().then((_) {
        if (!mounted) return;
        ref.read(locationProvider.notifier).startTracking();
      });
    });
    _startCooldownTimer();
  }

  void _startCooldownTimer() {
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) ref.read(sosProvider.notifier).updateCooldown();
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send SOS Alert?'),
        content: const Text(
          'This will send your current location to all administrators. '
          'Are you sure you want to send an emergency alert?',
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
      final location =
          await ref.read(locationProvider.notifier).getCurrentLocation();

      if (!mounted) return;

      if (location == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location. Please enable GPS.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final success = await sosNotifier.sendSOSAlert(
        userId: user.id,
        userName: user.fullName,
        userEmail: user.email,
        matricNumber: user.matricNumber,
        phoneNumber: user.phoneNumber,
        latitude: location.latitude,
        longitude: location.longitude,
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
            content: Text(error ?? 'Failed to send SOS alert'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(locationProvider.notifier).stopTracking();
      await ref.read(authProvider.notifier).signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 1:
        return const SOSScreen();
      case 2:
        return const ProfileScreen();
      default:
        return _buildHomeScaffold();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use Stack instead of IndexedStack — only renders visited tabs
      body: Stack(
        children: List.generate(3, (index) {
          final isVisible = index == _currentIndex;
          final hasBeenVisited = _visitedTabs.contains(index);

          if (!hasBeenVisited) return const SizedBox.shrink();

          return Offstage(
            offstage: !isVisible,
            child: _buildTab(index),
          );
        }),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _visitedTabs.add(index); // lazy load — build only when visited
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emergency_outlined),
              activeIcon: Icon(Icons.emergency),
              label: 'SOS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScaffold() {
    final user = ref.watch(currentUserProvider);
    final locationState = ref.watch(locationProvider);
    final sosState = ref.watch(sosProvider);

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user?.fullName ?? 'Student'}!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stay safe today',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.grey400
                                        : AppColors.grey500,
                                  ),
                        ),
                      ],
                    ),
                    GlassmorphicButton(
                      onPressed: _handleLogout,
                      padding: const EdgeInsets.all(12),
                      child: const Icon(Icons.logout, color: AppColors.error),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                GlassmorphicContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'Emergency SOS',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the button below if you need immediate help',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.grey400
                                  : AppColors.grey500,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SOSButton(
                        onPressed: _handleSOS,
                        isLoading: sosState.isSendingAlert,
                        cooldown: sosState.remainingCooldown,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                        icon: Icons.location_on,
                        title: 'Location',
                        value: locationState.currentLocation != null
                            ? 'Active'
                            : 'Inactive',
                        color: locationState.currentLocation != null
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusCard(
                        icon: Icons.security,
                        title: 'Status',
                        value: 'Protected',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (locationState.currentLocation != null)
                  GlassmorphicContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.my_location,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text('Your Location',
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          locationState.currentLocation!.formattedCoordinates,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                        ),
                        if (locationState.currentLocation!.accuracy != null)
                          ...[
                          const SizedBox(height: 4),
                          Text(
                            'Accuracy: ${locationState.currentLocation!.accuracy!.toStringAsFixed(0)}m',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.grey500
                                      : AppColors.grey400,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                if (user != null && !user.isProfileComplete)
                  GlassmorphicContainer(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.warning.withValues(alpha: 0.2),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.5)),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: AppColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Complete Your Profile',
                                  style:
                                      Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 4),
                              Text(
                                'Add your emergency contact to get better help',
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
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: () =>
                              setState(() => _currentIndex = 2),
                        ),
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

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.grey400
                      : AppColors.grey500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}