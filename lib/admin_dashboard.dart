import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jivan_swad_app/provider/manage_orders.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String message = "";

  // 🔹 Add a record to adminData collection
  Future<void> addAdminData() async {
    try {
      await _firestore.collection('adminData').add({
        'info': 'Admin created a new record at ${DateTime.now()}',
        'createdBy': _auth.currentUser!.email,
        'time': DateTime.now(),
      });
      setState(() => message = "✅ Data added to adminData successfully!");
    } catch (e) {
      setState(() => message = "❌ Failed to write: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final CollectionReference adminData = _firestore.collection('adminData');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome Admin: ${user?.email ?? ''}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),

            // 🔹 Button to add data to adminData
            ElevatedButton(
              onPressed: addAdminData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("➕ Add Data to adminData"),
            ),

            const SizedBox(height: 10),

            // 🔹 NEW: Button to add sample order
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('orders').add({
                  'customerName': 'Sample User',
                  'total': 19.99,
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                  'items': [
                    {'name': 'Masala Tea', 'qty': 1},
                    {'name': 'Cold Coffee', 'qty': 2},
                  ],
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Sample order added!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Sample Order'),
            ),

            const SizedBox(height: 10),
            Text(message, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 10),

            // 🔹 Navigation to Manage Orders screen
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Manage Orders'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ManageOrdersScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            const Text("📄 Admin Data", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),

            // 🔹 Firestore StreamBuilder
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: adminData.orderBy('time', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No admin data found."));
                  }

                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(data['info'] ?? 'No info'),
                          subtitle: Text("Created by: ${data['createdBy']}"),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
