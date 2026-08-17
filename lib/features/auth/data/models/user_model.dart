enum UserRole { student, admin }

class UserModel {
  final String id;
  final String email;
  final UserRole role;
  final String? fullName;
  final String? matricNumber;
  final String? phoneNumber;
  final String? emergencyContact;
  final String? department;
  final String? address;
  final String? ongoingSickness;
  final String? bloodType;
  final String? allergies;
  final String? genotype;
  final int? age;
  final String? priorIllness;
  final String? chronicConditions;
  final String? currentMedications;
  final String? profileImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.matricNumber,
    this.phoneNumber,
    this.emergencyContact,
    this.department,
    this.address,
    this.ongoingSickness,
    this.bloodType,
    this.allergies,
    this.genotype,
    this.age,
    this.priorIllness,
    this.chronicConditions,
    this.currentMedications,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] == 'admin' ? UserRole.admin : UserRole.student,
      fullName: json['full_name'],
      matricNumber: json['matric_number'],
      phoneNumber: json['phone_number'],
      emergencyContact: json['emergency_contact'],
      department: json['department'],
      address: json['address'],
      ongoingSickness: json['ongoing_sickness'],
      bloodType: json['blood_type'],
      allergies: json['allergies'],
      genotype: json['genotype'],
      age: json['age'],
      priorIllness: json['prior_illness'],
      chronicConditions: json['chronic_conditions'],
      currentMedications: json['current_medications'],
      profileImage: json['profile_image'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role == UserRole.admin ? 'admin' : 'student',
      'full_name': fullName,
      'matric_number': matricNumber,
      'phone_number': phoneNumber,
      'emergency_contact': emergencyContact,
      'department': department,
      'address': address,
      'ongoing_sickness': ongoingSickness,
      'blood_type': bloodType,
      'allergies': allergies,
      'genotype': genotype,
      'age': age,
      'prior_illness': priorIllness,
      'chronic_conditions': chronicConditions,
      'current_medications': currentMedications,
      'profile_image': profileImage,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id, String? email, UserRole? role,
    String? fullName, String? matricNumber, String? phoneNumber,
    String? emergencyContact, String? department, String? address,
    String? ongoingSickness, String? bloodType, String? allergies,
    String? genotype, int? age, String? priorIllness,
    String? chronicConditions, String? currentMedications,
    String? profileImage, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id, email: email ?? this.email, role: role ?? this.role,
      fullName: fullName ?? this.fullName, matricNumber: matricNumber ?? this.matricNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber, emergencyContact: emergencyContact ?? this.emergencyContact,
      department: department ?? this.department, address: address ?? this.address,
      ongoingSickness: ongoingSickness ?? this.ongoingSickness, bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies, genotype: genotype ?? this.genotype,
      age: age ?? this.age, priorIllness: priorIllness ?? this.priorIllness,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      currentMedications: currentMedications ?? this.currentMedications,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isProfileComplete =>
      fullName != null && matricNumber != null &&
      phoneNumber != null && emergencyContact != null && department != null;
}