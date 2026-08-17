import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:safeguard/core/utils/firebase_helper.dart';
import 'package:safeguard/features/auth/data/models/user_model.dart';

class AuthException implements Exception {
  final String message;
  final String? code;
  final AuthErrorType type;

  AuthException({
    required this.message,
    this.code,
    required this.type,
  });

  @override
  String toString() => message;
}

enum AuthErrorType {
  emailNotConfirmed,
  invalidCredentials,
  userNotFound,
  weakPassword,
  emailAlreadyInUse,
  networkError,
  unknown,
}

class AuthRepository {
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final credential = await FirebaseHelper.signUp(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user');
      }

      final userId = credential.user!.uid;
      debugPrint('Sign up successful - User ID: $userId, Role: $role');

      // Create profile in Firestore
      await FirebaseHelper.createProfile({
        'id': userId,
        'email': email,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      });

      return UserModel(
        id: userId,
        email: email,
        role: role == 'admin' ? UserRole.admin : UserRole.student,
        createdAt: DateTime.now(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseHelper.signIn(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw AuthException(
          message: 'Failed to sign in. Please check your credentials.',
          type: AuthErrorType.invalidCredentials,
        );
      }

      final profile = await FirebaseHelper.getProfile(credential.user!.uid);
      if (profile != null) {
        return UserModel.fromJson(profile);
      }

      return UserModel(
        id: credential.user!.uid,
        email: credential.user!.email!,
        role: UserRole.student,
        createdAt: DateTime.now(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  Future<bool> resendConfirmationEmail(String email) async {
    // Firebase doesn't require email confirmation by default
    // This is a no-op but kept for interface compatibility
    return true;
  }

  Future<void> signOut() async => await FirebaseHelper.signOut();

  UserModel? get currentUser {
    final user = FirebaseHelper.currentUser;
    if (user == null) return null;
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      role: UserRole.student, // will be overridden by profile fetch
    );
  }

  Stream<UserModel?> get authStateChanges {
    return FirebaseHelper.authStateChanges.asyncMap((user) async {
      if (user == null) return null;
      final profile = await FirebaseHelper.getProfile(user.uid);
      if (profile != null) return UserModel.fromJson(profile);
      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        role: UserRole.student,
      );
    });
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await FirebaseHelper.updateProfile(userId, data);
  }

  Future<UserModel?> getProfile(String userId) async {
    final profile = await FirebaseHelper.getProfile(userId);
    if (profile == null) return null;
    return UserModel.fromJson(profile);
  }

  Future<void> createProfile(UserModel user) async {
    await FirebaseHelper.createProfile({
      'id': user.id,
      'email': user.email,
      'role': user.role == UserRole.admin ? 'admin' : 'student',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  AuthException _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException(
          message: 'No account found with this email address.',
          code: e.code,
          type: AuthErrorType.userNotFound,
        );
      case 'wrong-password':
      case 'invalid-credential':
        return AuthException(
          message: 'Invalid email or password. Please try again.',
          code: e.code,
          type: AuthErrorType.invalidCredentials,
        );
      case 'email-already-in-use':
        return AuthException(
          message: 'An account already exists with this email.',
          code: e.code,
          type: AuthErrorType.emailAlreadyInUse,
        );
      case 'weak-password':
        return AuthException(
          message: 'Password is too weak. Use at least 6 characters.',
          code: e.code,
          type: AuthErrorType.weakPassword,
        );
      case 'network-request-failed':
        return AuthException(
          message: 'Network error. Please check your internet connection.',
          code: e.code,
          type: AuthErrorType.networkError,
        );
      default:
        return AuthException(
          message: e.message ?? 'An error occurred. Please try again.',
          code: e.code,
          type: AuthErrorType.unknown,
        );
    }
  }
}
