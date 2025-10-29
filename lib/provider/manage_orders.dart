// lib/provider/manage_orders.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum OrderStatus { pending, processing, shipped, delivered, cancelled }

String orderStatusToString(OrderStatus s) => s.name;

OrderStatus orderStatusFromString(String s) {
  return OrderStatus.values.firstWhere(
    (e) => e.name == s,
    orElse: () => OrderStatus.pending,
  );
}

class ManageOrdersScreen extends StatelessWidget {
  const ManageOrdersScreen({super.key});

  // ✅ Removed the extra import line
  Future<void> _updateStatus(String id, OrderStatus s) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(id)
        .update({'status': orderStatusToString(s)});
  }

  void _showDetails(BuildContext context, DocumentSnapshot d) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Order ${d.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Customer: ${d['customerName'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            ...(List.from(d['items'] ?? [])).map(
              (it) => ListTile(
                title: Text(it['name'] ?? ''),
                subtitle: Text('Qty: ${it['qty']}'),
              ),
            ),
            const Divider(),
            Text('Total: \$${(d['total'] ?? 0).toString()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersStream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final status = orderStatusFromString(d['status'] ?? 'pending');

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: ListTile(
                  title: Text(
                      'Order ${d.id} — ${d['customerName'] ?? 'Customer'}'),
                  subtitle: Text(
                    'Total: \$${(d['total'] ?? 0).toString()} • Status: ${status.name}',
                  ),
                  trailing: PopupMenuButton<OrderStatus>(
                    onSelected: (s) => _updateStatus(d.id, s),
                    itemBuilder: (_) => OrderStatus.values
                        .map((s) => PopupMenuItem(
                              value: s,
                              child: Text(s.name),
                            ))
                        .toList(),
                  ),
                  onTap: () => _showDetails(context, d),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
