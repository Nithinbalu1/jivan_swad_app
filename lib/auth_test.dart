import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthTestPage extends StatefulWidget {
  const AuthTestPage({super.key});

  @override
  State<AuthTestPage> createState() => _AuthTestPageState();
}

class _AuthTestPageState extends State<AuthTestPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String role = 'Customer';
  String message = "";

  Future<void> signUp() async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // store role and email in Firestore
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': emailController.text.trim(),
        'role': role,
        'createdAt': DateTime.now(),
      });

      setState(() => message = "✅ Sign-Up successful! Role: $role");
    } catch (e) {
      setState(() => message = "❌ Sign-Up failed: $e");
    }
  }

  Future<void> login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final userRole = doc['role'];

        if (userRole == 'Admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/customer');
        }
      }
    } catch (e) {
      setState(() => message = "❌ Login failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true),

            // Role dropdown
            DropdownButton<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: 'Customer', child: Text('Customer')),
                DropdownMenuItem(value: 'Admin', child: Text('Admin')),
              ],
              onChanged: (value) => setState(() => role = value!),
            ),

            const SizedBox(height: 16),
            ElevatedButton(onPressed: signUp, child: const Text('Sign Up')),
            ElevatedButton(onPressed: login, child: const Text('Login')),
            const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
