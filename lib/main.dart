import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jivan_swad_app/provider/manage_orders.dart';
import 'package:jivan_swad_app/screens/login_screen.dart';
import 'package:jivan_swad_app/provider/provider_home.dart';
import 'package:jivan_swad_app/screens/customer_home.dart';
import 'package:jivan_swad_app/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jivan Swad App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/manageOrders': (context) => const ManageOrdersScreen(),
      },
    );
  }
}

/// 🔹 AuthGate decides where to send the user based on login state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in
        if (snapshot.hasData) {
          // Determine user's role and route accordingly
          return FutureBuilder<String?>(
            future: AuthService.getRole(),
            builder: (context, roleSnap) {
              if (roleSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final role = roleSnap.data?.toString().toLowerCase();
              // Debug: print role to help diagnose routing issues
              // (This can be removed after verification)
              // ignore: avoid_print
              print('AuthGate: resolved role="$role"');
              if (role == 'admin') {
                // Admins use the provider dashboard
                // ignore: avoid_print
                print('AuthGate: routing to ProviderHome');
                return const ProviderHome();
              }
              // ignore: avoid_print
              print('AuthGate: routing to CustomerHome');
              return const CustomerHome();
            },
          );
        }

        // Otherwise go to login screen
        return const LoginScreen();
      },
    );
  }
}
