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
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(id)
          .update({'status': orderStatusToString(s)});
    } catch (e) {
      // Surface failure to caller via rethrow so UI can show a message
      throw Exception('Failed to update order status: $e');
    }
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
            // Handle items stored as List or Map
            ..._buildItemListTiles(d['items']),
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

  // Helper to build list tiles for order items that may be stored as a List or a Map
  List<Widget> _buildItemListTiles(dynamic itemsRaw) {
    final List items = [];
    if (itemsRaw is Iterable) {
      items.addAll(itemsRaw);
    } else if (itemsRaw is Map) {
      items.addAll(itemsRaw.values);
    }

    return items.where((it) => it is Map).map<Widget>((it) {
      final name = it['name'] ?? it['title'] ?? '';
      final qty = it['qty'] ?? it['quantity'] ?? 0;
      return ListTile(
        title: Text(name.toString()),
        subtitle: Text('Qty: ${qty.toString()}'),
      );
    }).toList();
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
          if (snap.hasError) {
            final err = snap.error;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error loading orders: $err'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        // Recreate this screen to retry the stream
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ManageOrdersScreen()),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
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
                    onSelected: (s) async {
                      try {
                        await _updateStatus(d.id, s);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Order status updated')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Failed to update status: $e')),
                          );
                        }
                      }
                    },
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
