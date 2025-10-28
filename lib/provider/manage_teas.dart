// lib/provider/manage_teas.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageTeasScreen extends StatefulWidget {
  const ManageTeasScreen({super.key});
  @override
  State<ManageTeasScreen> createState() => _ManageTeasScreenState();
}

class _ManageTeasScreenState extends State<ManageTeasScreen> {
  final CollectionReference teasRef = FirebaseFirestore.instance.collection('teas');

  Future<void> _showEditDialog({DocumentSnapshot? doc}) async {
    final nameCtrl = TextEditingController(text: doc != null ? doc['name'] ?? '' : '');
    final priceCtrl = TextEditingController(text: doc != null ? (doc['price']?.toString() ?? '') : '');
    final stockCtrl = TextEditingController(text: doc != null ? (doc['stock']?.toString() ?? '0') : '0');
    final descCtrl = TextEditingController(text: doc != null ? doc['description'] ?? '' : '');
    final imgCtrl = TextEditingController(text: doc != null ? doc['imageUrl'] ?? '' : '');

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doc == null ? 'Add Tea' : 'Edit Tea'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                TextFormField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
                TextFormField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
                TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                TextFormField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'Image URL (optional)')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final data = {
                'name': nameCtrl.text.trim(),
                'price': double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                'stock': int.tryParse(stockCtrl.text.trim()) ?? 0,
                'description': descCtrl.text.trim(),
                'imageUrl': imgCtrl.text.trim(),
              };
              if (doc == null) {
                await teasRef.add(data);
              } else {
                await teasRef.doc(doc.id).update(data);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(DocumentSnapshot doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Tea'),
        content: Text('Delete "${doc['name']}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await teasRef.doc(doc.id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Teas')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showEditDialog(),
        tooltip: 'Add Tea',
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: teasRef.orderBy('name').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No teas found. Tap + to add.'));
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final img = (d['imageUrl'] ?? '').toString();
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: img.isNotEmpty ? CircleAvatar(backgroundImage: NetworkImage(img)) : const CircleAvatar(child: Icon(Icons.local_cafe)),
                  title: Text(d['name'] ?? ''),
                  subtitle: Text('\$${(d['price'] ?? 0).toString()} • Stock: ${(d['stock'] ?? 0).toString()}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _showEditDialog(doc: d);
                      if (v == 'del') _confirmDelete(d);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'del', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
