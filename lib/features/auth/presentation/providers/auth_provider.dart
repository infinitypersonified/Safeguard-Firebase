import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeguard/features/auth/data/models/user_model.dart';
import 'package:safeguard/features/auth/data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final user = _repository.currentUser;
    if (user != null) {
      final profile = await _repository.getProfile(user.id);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: profile ?? user,
      );
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        role: role,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.signIn(
        email: email,
        password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.signOut();
      state = AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String matricNumber,
    required String phoneNumber,
    required String emergencyContact,
    required String department,
    String? address,
    String? ongoingSickness,
    String? bloodType,
    String? allergies,
    String? genotype,
    int? age,
    String? priorIllness,
    String? chronicConditions,
    String? currentMedications,
  }) async {
    if (state.user == null) return;
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.updateProfile(state.user!.id, {
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
        'updated_at': DateTime.now().toIso8601String(),
      });
      final updatedUser = await _repository.getProfile(state.user!.id);
      state = AuthState(status: AuthStatus.authenticated, user: updatedUser);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);

  Future<bool> resendConfirmation(String email) async {
    try {
      return await _repository.resendConfirmationEmail(email);
    } catch (e) {
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});

final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role == UserRole.admin;
});

final isStudentProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role == UserRole.student;
});
