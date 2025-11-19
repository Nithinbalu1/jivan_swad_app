import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple helper to persist small per-user preferences to the user's document.
class UserPrefs {
  UserPrefs._();
  static final UserPrefs instance = UserPrefs._();

  final CollectionReference _users =
      FirebaseFirestore.instance.collection('users');

  Future<void> saveLocation(String uid, String? location) async {
    try {
      await _users
          .doc(uid)
          .set({'selectedLocation': location}, SetOptions(merge: true));
    } catch (_) {
      // swallow for now; AppState will still keep in-memory value
    }
  }

  Future<void> savePickup(String uid, DateTime? dt) async {
    try {
      final data = dt == null
          ? {'pickupAt': FieldValue.delete()}
          : {'pickupAt': Timestamp.fromDate(dt)};
      await _users.doc(uid).set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> saveDeliveryAddress(String uid, String? address) async {
    try {
      await _users
          .doc(uid)
          .set({'deliveryAddress': address}, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> saveServiceType(String uid, String? serviceType) async {
    try {
      await _users
          .doc(uid)
          .set({'serviceType': serviceType}, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Loads prefs (selectedLocation and pickupAt) from the user's doc.
  Future<Map<String, dynamic>> loadPrefs(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return {};
      final data = doc.data() as Map<String, dynamic>;
      return data;
    } catch (_) {
      return {};
    }
  }
}
