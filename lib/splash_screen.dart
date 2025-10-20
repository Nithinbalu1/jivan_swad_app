import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _navigateUser();
  }

  Future<void> _navigateUser() async {
    await Future.delayed(const Duration(seconds: 2));

    final user = _auth.currentUser;

    if (!mounted) return; // prevents context errors if widget disposed

    if (user == null) {
      // no user logged in → go to login
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final role = doc['role'];

        if (role == 'Admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/customer');
        }
      } catch (e) {
        // fallback in case Firestore fetch fails
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Checking session...", style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
