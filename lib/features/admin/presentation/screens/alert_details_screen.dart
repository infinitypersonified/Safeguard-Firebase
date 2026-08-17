import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safeguard/core/theme/app_theme.dart';
import 'package:safeguard/core/widgets/animated_button.dart';
import 'package:safeguard/core/widgets/glassmorphic_container.dart';
import 'package:safeguard/features/sos/data/models/sos_alert_model.dart';
import 'package:safeguard/features/sos/presentation/providers/sos_provider.dart';

class AlertDetailsScreen extends ConsumerStatefulWidget {
  final SOSAlertModel alert;

  const AlertDetailsScreen({super.key, required this.alert});

  @override
  ConsumerState<AlertDetailsScreen> createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends ConsumerState<AlertDetailsScreen> {
  MapController? _mapController;
  bool _isLoading = false;

  // Local copy of alert so UI updates after resolve/acknowledge
  late SOSAlertModel _alert;

  static const String _mapTilerApiKey = '6gyau8l4EnP51EiT7u4A';

  @override
  void initState() {
    super.initState();
    _alert = widget.alert;
  }

  @override
  Widget build(BuildContext context) {
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
                            'Alert Details',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'ID: ${_alert.id.substring(0, 8)}...',
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
                    _buildStatusBadge(_alert.status),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Map
                      GlassmorphicContainer(
                        padding: EdgeInsets.zero,
                        height: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                _alert.latitude,
                                _alert.longitude,
                              ),
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
                                  Marker(
                                    point: LatLng(
                                      _alert.latitude,
                                      _alert.longitude,
                                    ),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: AppColors.error,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Student Info
                      GlassmorphicContainer(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryDark,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  (_alert.userName ?? 'U')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _alert.userName ?? 'Unknown',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (_alert.matricNumber != null)
                                    Text(
                                      _alert.matricNumber!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color:
                                                Theme.of(context).brightness ==
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
                      ),
                      const SizedBox(height: 16),

                      // Medical Info
                      GlassmorphicContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Medical Info',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            if (_alert.bloodType != null)
                              _buildInfoRow(Icons.opacity, 'Blood Type',
                                  _alert.bloodType!),
                            if (_alert.allergies != null)
                              _buildInfoRow(Icons.all_inclusive, 'Allergies',
                                  _alert.allergies!),
                            if (_alert.ongoingSickness != null)
                              _buildInfoRow(Icons.healing, 'Ongoing Sickness',
                                  _alert.ongoingSickness!),
                            if (_alert.genotype != null)
                              _buildInfoRow(
                                  Icons.favorite, 'Genotype', _alert.genotype!),
                            if (_alert.priorIllness != null)
                              _buildInfoRow(Icons.medical_services,
                                  'Prior Illness', _alert.priorIllness!),
                            if (_alert.chronicConditions != null)
                              _buildInfoRow(Icons.coronavirus, 'Chronic',
                                  _alert.chronicConditions!),
                            if (_alert.currentMedications != null)
                              _buildInfoRow(Icons.local_pharmacy, 'Medications',
                                  _alert.currentMedications!),
                            if (_alert.age != null)
                              _buildInfoRow(
                                  Icons.cake, 'Age', _alert.age.toString()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Contact Info
                      GlassmorphicContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Information',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            if (_alert.phoneNumber != null)
                              _buildInfoRow(
                                  Icons.phone, 'Phone', _alert.phoneNumber!),
                            if (_alert.userEmail != null)
                              _buildInfoRow(
                                  Icons.email, 'Email', _alert.userEmail!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location Info
                      GlassmorphicContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.location_on,
                              'Coordinates',
                              '${_alert.latitude.toStringAsFixed(6)}, ${_alert.longitude.toStringAsFixed(6)}',
                            ),
                            if (_alert.address != null)
                              _buildInfoRow(
                                  Icons.place, 'Address', _alert.address!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Timeline
                      GlassmorphicContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Timeline',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.access_time,
                              'Alert Time',
                              _formatDateTime(_alert.createdAt),
                            ),
                            if (_alert.resolvedAt != null)
                              _buildInfoRow(
                                Icons.check_circle,
                                'Resolved At',
                                _formatDateTime(_alert.resolvedAt!),
                              ),
                            if (_alert.isResolved)
                              _buildInfoRow(
                                Icons.timer,
                                'Response Time',
                                _alert.formattedResponseTime,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      if (_alert.isPending) ...[
                        AnimatedGradientButton(
                          onPressed: _isLoading ? null : () => _handleResolve(),
                          isLoading: _isLoading,
                          text: 'Mark as Resolved',
                          gradientColors: const [
                            AppColors.success,
                            AppColors.successDark,
                          ],
                        ),
                        const SizedBox(height: 12),
                        AnimatedGradientButton(
                          onPressed:
                              _isLoading ? null : () => _handleAcknowledge(),
                          isLoading: _isLoading,
                          text: 'Acknowledge',
                          gradientColors: const [
                            AppColors.warning,
                            AppColors.warningDark,
                          ],
                        ),
                      ],
                      if (_alert.isAcknowledged) ...[
                        AnimatedGradientButton(
                          onPressed: _isLoading ? null : () => _handleResolve(),
                          isLoading: _isLoading,
                          text: 'Mark as Resolved',
                          gradientColors: const [
                            AppColors.success,
                            AppColors.successDark,
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'pending':
        color = AppColors.error;
        text = 'Pending';
        break;
      case 'acknowledged':
        color = AppColors.warning;
        text = 'Acknowledged';
        break;
      case 'resolved':
        color = AppColors.success;
        text = 'Resolved';
        break;
      default:
        color = AppColors.grey500;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.grey500
                            : AppColors.grey400,
                      ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleResolve() async {
    setState(() => _isLoading = true);

    final success = await ref.read(sosProvider.notifier).updateAlertStatus(
          _alert.id,
          'resolved',
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      // Refresh the alerts list in the dashboard
      await ref.read(sosProvider.notifier).refreshAlerts();
      if (!mounted) return;

      // Update local alert status so badge updates instantly
      setState(() {
        _alert = _alert.copyWith(
          status: 'resolved',
          resolvedAt: DateTime.now(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert marked as resolved'),
          backgroundColor: AppColors.success,
        ),
      );

      // Go back to dashboard — resolved tab will now show this alert
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update alert. Check your permissions.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleAcknowledge() async {
    setState(() => _isLoading = true);

    final success = await ref.read(sosProvider.notifier).updateAlertStatus(
          _alert.id,
          'acknowledged',
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      await ref.read(sosProvider.notifier).refreshAlerts();
      if (!mounted) return;

      // Update local state so buttons update instantly
      setState(() {
        _alert = _alert.copyWith(status: 'acknowledged');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert acknowledged'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to acknowledge alert. Check your permissions.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
