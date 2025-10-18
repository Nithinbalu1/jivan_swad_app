import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_home.dart';
import 'customer_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;
  String role = 'customer';
  String message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jivan Swad Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 12),
            if (!isLogin)
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('Customer')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setState(() => role = v!),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                try {
                  if (isLogin) {
                    await AuthService.login(
                      emailController.text.trim(),
                      passwordController.text.trim(),
                    );
                  } else {
                    await AuthService.register(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                      role: role,
                    );
                  }

                  final userRole = await AuthService.getRole();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => userRole == 'admin'
                          ? const AdminHome()
                          : const CustomerHome(),
                    ),
                  );
                } catch (e) {
                  setState(() => message = e.toString());
                }
              },
              child: Text(isLogin ? 'Login' : 'Sign Up'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin
                  ? 'Create Account'
                  : 'Already have an account? Login'),
            ),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(message, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
