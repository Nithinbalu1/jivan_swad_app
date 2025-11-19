import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_prefs.dart';

/// Lightweight app-wide state for simple shared selections (location, pickup time).
/// Persists values to `users/{uid}` when a user is signed in.
class AppState {
  AppState._() {
    // Listen for auth changes and load user prefs when available.
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        // clear to defaults when signed out
        selectedLocation.value = null;
        selectedPickup.value = null;
      } else {
        // load saved prefs
        final data = await UserPrefs.instance.loadPrefs(user.uid);
        final loc = data['selectedLocation'] as String?;
        final pickup = data['pickupAt'];
        DateTime? dt;
        if (pickup is Timestamp) dt = pickup.toDate();
        selectedLocation.value = loc ?? selectedLocation.value;
        selectedPickup.value = dt ?? selectedPickup.value;
        // load delivery address and service type if present
        final delivery = data['deliveryAddress'] as String?;
        final svc = data['serviceType'] as String?;
        deliveryAddress.value = delivery ?? deliveryAddress.value;
        serviceType.value = svc ?? serviceType.value;
      }
    });
  }

  static final AppState instance = AppState._();

  final ValueNotifier<String?> selectedLocation = ValueNotifier<String?>(null);
  final ValueNotifier<DateTime?> selectedPickup =
      ValueNotifier<DateTime?>(null);
  final ValueNotifier<String?> deliveryAddress = ValueNotifier<String?>(null);
  final ValueNotifier<String> serviceType = ValueNotifier<String>('pickup');

  void setLocation(String? location) {
    selectedLocation.value = location;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      UserPrefs.instance.saveLocation(user.uid, location);
    }
  }

  void setDeliveryAddress(String? address) {
    deliveryAddress.value = address;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      UserPrefs.instance.saveDeliveryAddress(user.uid, address);
    }
  }

  void setServiceType(String type) {
    serviceType.value = type;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      UserPrefs.instance.saveServiceType(user.uid, type);
    }
  }

  void setPickup(DateTime? dt) {
    selectedPickup.value = dt;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      UserPrefs.instance.savePickup(user.uid, dt);
    }
  }
}
