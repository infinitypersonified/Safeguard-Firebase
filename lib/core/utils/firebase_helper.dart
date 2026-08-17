import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static FirebaseAuth get auth => _auth;
  static FirebaseFirestore get db => _db;

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async => await _auth.signOut();

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Profiles ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    final doc = await _db.collection('profiles').doc(userId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  static Future<void> createProfile(Map<String, dynamic> profile) async {
    final id = profile['id'] as String;
    final data = Map<String, dynamic>.from(profile)..remove('id');
    await _db.collection('profiles').doc(id).set(data);
  }

  static Future<void> updateProfile(
      String userId, Map<String, dynamic> data) async {
    await _db.collection('profiles').doc(userId).update(data);
  }

  // ── SOS Alerts ────────────────────────────────────────────────────────────

  static Future<void> createSOSAlert(Map<String, dynamic> alert) async {
    final id = alert['id'] as String;
    final data = Map<String, dynamic>.from(alert)..remove('id');
    data['created_at'] = FieldValue.serverTimestamp();
    await _db.collection('sos_alerts').doc(id).set(data);
  }

  static Stream<List<Map<String, dynamic>>> watchSOSAlerts() {
    return _db
        .collection('sos_alerts')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              // Convert Timestamp to ISO string for model parsing
              if (data['created_at'] is Timestamp) {
                data['created_at'] =
                    (data['created_at'] as Timestamp).toDate().toIso8601String();
              }
              if (data['resolved_at'] is Timestamp) {
                data['resolved_at'] =
                    (data['resolved_at'] as Timestamp).toDate().toIso8601String();
              }
              return data;
            }).toList());
  }

  static Future<void> updateAlertStatus(
      String alertId, String status) async {
    final update = <String, dynamic>{'status': status};
    if (status == 'resolved') {
      update['resolved_at'] = FieldValue.serverTimestamp();
    }
    await _db.collection('sos_alerts').doc(alertId).update(update);
  }

  static Future<List<Map<String, dynamic>>> getAllAlerts() async {
    final snap = await _db
        .collection('sos_alerts')
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      if (data['created_at'] is Timestamp) {
        data['created_at'] =
            (data['created_at'] as Timestamp).toDate().toIso8601String();
      }
      if (data['resolved_at'] is Timestamp) {
        data['resolved_at'] =
            (data['resolved_at'] as Timestamp).toDate().toIso8601String();
      }
      return data;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getAlertHistory() async {
    final snap = await _db
        .collection('sos_alerts')
        .where('status', isEqualTo: 'resolved')
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      if (data['created_at'] is Timestamp) {
        data['created_at'] =
            (data['created_at'] as Timestamp).toDate().toIso8601String();
      }
      if (data['resolved_at'] is Timestamp) {
        data['resolved_at'] =
            (data['resolved_at'] as Timestamp).toDate().toIso8601String();
      }
      return data;
    }).toList();
  }

  static Future<int> getUnreadAlertCount() async {
    final snap = await _db
        .collection('sos_alerts')
        .where('status', isEqualTo: 'pending')
        .get();
    return snap.docs.length;
  }

  // ── Location History ──────────────────────────────────────────────────────

  static Future<void> updateLocation(
      String userId, Map<String, dynamic> location) async {
    await _db.collection('location_history').add({
      'user_id': userId,
      ...location,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  static Future<void> createNotification(
      Map<String, dynamic> notification) async {
    notification['created_at'] = FieldValue.serverTimestamp();
    await _db.collection('notifications').add(notification);
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'is_read': true});
  }

  static Stream<List<Map<String, dynamic>>> watchNotifications(
      String userId) {
    return _db
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              if (data['created_at'] is Timestamp) {
                data['created_at'] =
                    (data['created_at'] as Timestamp).toDate().toIso8601String();
              }
              return data;
            }).toList());
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAdminIds() async {
    final snap = await _db
        .collection('profiles')
        .where('role', isEqualTo: 'admin')
        .get();
    return snap.docs.map((doc) => {'id': doc.id}).toList();
  }
}
