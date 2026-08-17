class SOSAlertModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String? matricNumber;
  final String? phoneNumber;
  final double latitude;
  final double longitude;
  final String? address;
  final String? bloodType;
  final String? allergies;
  final String? ongoingSickness;
  final String? genotype;
  final String? priorIllness;
  final String? chronicConditions;
  final String? currentMedications;
  final int? age;
  final String status; // pending, acknowledged, resolved
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final String? notes;

  SOSAlertModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    this.matricNumber,
    this.phoneNumber,
    required this.latitude,
    required this.longitude,
    this.address,
    this.bloodType,
    this.allergies,
    this.ongoingSickness,
    this.genotype,
    this.priorIllness,
    this.chronicConditions,
    this.currentMedications,
    this.age,
    required this.status,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
    this.notes,
  });

  factory SOSAlertModel.fromJson(Map<String, dynamic> json) {
    return SOSAlertModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'],
      userEmail: json['user_email'],
      matricNumber: json['matric_number'],
      phoneNumber: json['phone_number'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address'],
      bloodType: json['blood_type'],
      allergies: json['allergies'],
      ongoingSickness: json['ongoing_sickness'],
      genotype: json['genotype'],
      priorIllness: json['prior_illness'],
      chronicConditions: json['chronic_conditions'],
      currentMedications: json['current_medications'],
      age: json['age'],
      status: json['status'] ?? 'pending',
      resolvedBy: json['resolved_by'],
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'matric_number': matricNumber,
      'phone_number': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'blood_type': bloodType,
      'allergies': allergies,
      'ongoing_sickness': ongoingSickness,
      'genotype': genotype,
      'prior_illness': priorIllness,
      'chronic_conditions': chronicConditions,
      'current_medications': currentMedications,
      'age': age,
      'status': status,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  SOSAlertModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? matricNumber,
    String? phoneNumber,
    double? latitude,
    double? longitude,
    String? address,
    String? bloodType,
    String? allergies,
    String? ongoingSickness,
    String? genotype,
    String? priorIllness,
    String? chronicConditions,
    String? currentMedications,
    int? age,
    String? status,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
    String? notes,
  }) {
    return SOSAlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      matricNumber: matricNumber ?? this.matricNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      ongoingSickness: ongoingSickness ?? this.ongoingSickness,
      genotype: genotype ?? this.genotype,
      priorIllness: priorIllness ?? this.priorIllness,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      currentMedications: currentMedications ?? this.currentMedications,
      age: age ?? this.age,
      status: status ?? this.status,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAcknowledged => status == 'acknowledged';
  bool get isResolved => status == 'resolved';

  Duration get responseTime {
    if (resolvedAt == null) return Duration.zero;
    return resolvedAt!.difference(createdAt);
  }

  String get formattedResponseTime {
    final duration = responseTime;
    if (duration.inMinutes < 1) return 'Less than a minute';
    if (duration.inMinutes < 60) return '${duration.inMinutes} min';
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }
}
