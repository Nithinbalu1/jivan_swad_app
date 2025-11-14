import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  /// Register a new user
  static Future<User?> register({
    required String email,
    required String password,
    required String role, // 'admin' or 'customer'
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store role in Firestore
      await _db.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'role': role.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return credential.user;
    } on FirebaseAuthException catch (e) {
      // Provide a clearer error message for callers
      final message = e.message ?? 'Registration failed (${e.code})';
      // ignore: avoid_print
      print('AuthService.register error: $e');
      throw Exception(message);
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.register unexpected error: $e');
      throw Exception('Registration failed. Please try again.');
    }
  }

  /// Login existing user
  static Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      final message = e.message ?? 'Login failed (${e.code})';
      // ignore: avoid_print
      print('AuthService.login error: $e');
      throw Exception(message);
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.login unexpected error: $e');
      throw Exception('Login failed. Please try again.');
    }
  }

  /// Get current user's role from Firestore
  static Future<String?> getRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final docRef = _db.collection('users').doc(uid);
    try {
      final doc = await docRef.get();
      final data = doc.data();
      if (data == null) return null;

      // Prefer explicit 'role' string field
      final roleField = data['role'];
      if (roleField != null) {
        return roleField.toString();
      }

      // Backward-compat: some setups used a boolean 'isAdmin'
      final isAdmin = data['isAdmin'];
      if (isAdmin is bool && isAdmin) return 'admin';

      return null;
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.getRole: failed to read user doc: $e');
      return null;
    }
  }

  /// Logout
  static Future<void> logout() => _auth.signOut();
}
