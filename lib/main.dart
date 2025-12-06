import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jivan_swad_app/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:jivan_swad_app/provider/manage_orders.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jivan_swad_app/screens/auth_screen.dart';
import 'package:jivan_swad_app/provider/provider_home.dart';
import 'package:jivan_swad_app/screens/customer_home_modern.dart';
import 'package:jivan_swad_app/services/auth_service.dart';
import 'package:jivan_swad_app/services/data_seeder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load local environment variables (optional). Create a `.env` in project root
  // with OPENAI_API_KEY=sk-... if you want direct client OpenAI calls.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // ignore - proceed if .env not present
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Emulator wiring is opt-in. Set the dart-define flag when running to enable:
  // flutter run -d chrome --dart-define=USE_FIREBASE_EMULATORS=true
  const bool kUseFirebaseEmulators =
      bool.fromEnvironment('USE_FIREBASE_EMULATORS', defaultValue: false);

  // If running in debug mode AND the opt-in flag is set, attempt to connect to
  // local Firebase emulators. Developers: start the emulators with
  // `firebase emulators:start` before running the app with the flag.
  if (kDebugMode && kUseFirebaseEmulators) {
    try {
      // Firestore emulator default host/port
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      // Auth emulator default host/port
      FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      // ignore: avoid_print
      print(
          'Using Firebase emulators: Firestore@localhost:8080 Auth@localhost:9099');
    } catch (e) {
      // ignore: avoid_print
      print('Failed to configure Firebase emulators: $e');
    }
  }

  // Seed initial data if database is empty (async, don't wait for it)
  DataSeeder.seedIfEmpty().catchError((e) {
    print('Warning: Failed to seed data - $e');
    return false;
  });

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
        '/auth': (context) => const AuthScreen(),
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
              print('AuthGate: routing to CustomerHomeModern');
              return const CustomerHomeModern();
            },
          );
        }

        // Otherwise go to auth screen
        return const AuthScreen();
      },
    );
  }
}
