import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeguard/core/theme/app_theme.dart';
import 'package:safeguard/core/widgets/animated_button.dart';
import 'package:safeguard/core/widgets/glassmorphic_container.dart';
import 'package:safeguard/features/auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _matricController;
  late TextEditingController _phoneController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _departmentController;
  late TextEditingController _addressController;
  late TextEditingController _ongoingSicknessController;
  late TextEditingController _bloodTypeController;
  late TextEditingController _allergiesController;
  late TextEditingController _genotypeController;
  late TextEditingController _ageController;
  late TextEditingController _priorIllnessController;
  late TextEditingController _chronicConditionsController;
  late TextEditingController _currentMedicationsController;

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _matricController = TextEditingController(text: user?.matricNumber ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _emergencyContactController =
        TextEditingController(text: user?.emergencyContact ?? '');
    _departmentController =
        TextEditingController(text: user?.department ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _ongoingSicknessController =
        TextEditingController(text: user?.ongoingSickness ?? '');
    _bloodTypeController =
        TextEditingController(text: user?.bloodType ?? '');
    _allergiesController =
        TextEditingController(text: user?.allergies ?? '');
    _genotypeController =
        TextEditingController(text: user?.genotype ?? '');
    _ageController =
        TextEditingController(text: user?.age?.toString() ?? '');
    _priorIllnessController =
        TextEditingController(text: user?.priorIllness ?? '');
    _chronicConditionsController =
        TextEditingController(text: user?.chronicConditions ?? '');
    _currentMedicationsController =
        TextEditingController(text: user?.currentMedications ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _matricController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _departmentController.dispose();
    _addressController.dispose();
    _ongoingSicknessController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _genotypeController.dispose();
    _ageController.dispose();
    _priorIllnessController.dispose();
    _chronicConditionsController.dispose();
    _currentMedicationsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await ref.read(authProvider.notifier).updateProfile(
          fullName: _fullNameController.text.trim(),
          matricNumber: _matricController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          emergencyContact: _emergencyContactController.text.trim(),
          department: _departmentController.text.trim(),
          address: _addressController.text.trim(),
          ongoingSickness: _ongoingSicknessController.text.trim(),
          bloodType: _bloodTypeController.text.trim(),
          allergies: _allergiesController.text.trim(),
          genotype: _genotypeController.text.trim(),
          age: int.tryParse(_ageController.text.trim()),
          priorIllness: _priorIllnessController.text.trim(),
          chronicConditions: _chronicConditionsController.text.trim(),
          currentMedications: _currentMedicationsController.text.trim(),
        );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (!_isEditing)
                        GlassmorphicButton(
                          onPressed: () =>
                              setState(() => _isEditing = true),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 4),
                              Text('Edit'),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Avatar
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (user?.fullName ?? 'U')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? AppColors.grey400
                                : AppColors.grey500,
                          ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Basic Info ──
                  _buildSectionHeader('Basic Information'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    enabled: _isEditing,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _matricController,
                    label: 'Matric Number',
                    icon: Icons.badge_outlined,
                    enabled: _isEditing,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emergencyContactController,
                    label: 'Emergency Contact',
                    icon: Icons.emergency_outlined,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _departmentController,
                    label: 'Department',
                    icon: Icons.school_outlined,
                    enabled: _isEditing,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on_outlined,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 32),

                  // ── Medical Info ──
                  _buildSectionHeader('Medical Information'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ageController,
                    label: 'Age',
                    icon: Icons.cake_outlined,
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _bloodTypeController,
                    label: 'Blood Type',
                    icon: Icons.bloodtype_outlined,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _genotypeController,
                    label: 'Genotype',
                    icon: Icons.science_outlined,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _allergiesController,
                    label: 'Allergies',
                    icon: Icons.warning_amber_outlined,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ongoingSicknessController,
                    label: 'Ongoing Sickness',
                    icon: Icons.medical_services_outlined,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _priorIllnessController,
                    label: 'Prior / Past Illness',
                    icon: Icons.history_outlined,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _chronicConditionsController,
                    label: 'Chronic Conditions',
                    icon: Icons.monitor_heart_outlined,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _currentMedicationsController,
                    label: 'Current Medications',
                    icon: Icons.medication_outlined,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 32),

                  // Save / Cancel buttons
                  if (_isEditing) ...[
                    AnimatedGradientButton(
                      onPressed: _handleSave,
                      isLoading: _isSaving,
                      text: 'Save Changes',
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        final u = ref.read(currentUserProvider);
                        _fullNameController.text = u?.fullName ?? '';
                        _matricController.text = u?.matricNumber ?? '';
                        _phoneController.text = u?.phoneNumber ?? '';
                        _emergencyContactController.text =
                            u?.emergencyContact ?? '';
                        _departmentController.text = u?.department ?? '';
                        _addressController.text = u?.address ?? '';
                        _ongoingSicknessController.text =
                            u?.ongoingSickness ?? '';
                        _bloodTypeController.text = u?.bloodType ?? '';
                        _allergiesController.text = u?.allergies ?? '';
                        _genotypeController.text = u?.genotype ?? '';
                        _ageController.text = u?.age?.toString() ?? '';
                        _priorIllnessController.text = u?.priorIllness ?? '';
                        _chronicConditionsController.text =
                            u?.chronicConditions ?? '';
                        _currentMedicationsController.text =
                            u?.currentMedications ?? '';
                        setState(() => _isEditing = false);
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Info card
                  GlassmorphicContainer(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your health information will be sent to administrators when you trigger an SOS alert.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.grey300
                                      : AppColors.grey600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return GlassmorphicContainer(
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
          filled: false,
        ),
        validator: validator,
      ),
    );
  }
}