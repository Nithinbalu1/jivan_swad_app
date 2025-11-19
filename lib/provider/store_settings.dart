import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Simple provider settings screen to manage store locations (admin/provider only)
class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final CollectionReference _stores =
      FirebaseFirestore.instance.collection('stores');

  @override
  Widget build(BuildContext context) {
    // final primaryColor = const Color(0xFF4DB5BD);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Store Settings',
            style: TextStyle(color: Colors.black87)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stores.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index == docs.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Store'),
                  ),
                );
              }

              final d = docs[index];
              final data = d.data() as Map<String, dynamic>;
              final name = data['name'] as String? ?? d.id;
              final address = data['address'] as String? ?? '';
              final phone = data['phone'] as String? ?? '';
              final status = data['status'] as String? ?? 'Closed now';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$address\n$phone\nStatus: $status'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        _showEditDialog(context, docId: d.id, initial: data),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context,
      {String? docId, Map<String, dynamic>? initial}) async {
    final nameCtrl = TextEditingController(text: initial?['name'] ?? '');
    final addrCtrl = TextEditingController(text: initial?['address'] ?? '');
    final phoneCtrl = TextEditingController(text: initial?['phone'] ?? '');
    String status = initial?['status'] ?? 'Closed now';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(docId == null ? 'Add Store' : 'Edit Store'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(labelText: 'Address')),
              TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'Open now', child: Text('Open now')),
                  DropdownMenuItem(
                      value: 'Closed now', child: Text('Closed now')),
                ],
                onChanged: (v) => status = v ?? status,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final address = addrCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide a name')));
                return;
              }

              final id = docId ??
                  name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
              await _stores.doc(id).set({
                'name': name,
                'address': address,
                'phone': phone,
                'status': status,
              }, SetOptions(merge: true));

              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
