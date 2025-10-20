import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String message = "";

  // 🔹 Function to add data to Firestore
  Future<void> addCustomerData() async {
    try {
      await _firestore.collection('customerData').add({
        'info': 'Customer added a new item at ${DateTime.now()}',
        'createdBy': _auth.currentUser!.email,
        'time': DateTime.now(),
      });
      setState(() => message = "✅ Data added to customerData successfully!");
    } catch (e) {
      setState(() => message = "❌ Failed to write: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final CollectionReference customerData =
        _firestore.collection('customerData');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Dashboard"),
        backgroundColor: Colors.orange,
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
            Text("Welcome Customer: ${user?.email ?? ''}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: addCustomerData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text("➕ Add Data to customerData"),
            ),
            const SizedBox(height: 10),
            Text(message, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 10),

            const Text("🛍️ Customer Data", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),

            // 🔹 Realtime Firestore stream
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    customerData.orderBy('time', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No customer data found."));
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
