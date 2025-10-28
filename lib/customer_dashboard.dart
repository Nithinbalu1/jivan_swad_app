import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.email ?? "Customer"}!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Available Items:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: const [
                  Card(child: ListTile(title: Text("Masala Tea"), subtitle: Text("\$2.99"))),
                  Card(child: ListTile(title: Text("Green Tea"), subtitle: Text("\$3.49"))),
                  Card(child: ListTile(title: Text("Cold Coffee"), subtitle: Text("\$4.00"))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
