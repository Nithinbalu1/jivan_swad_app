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
            //Handle items stored as List or Map
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

    return items.whereType<Map>().map<Widget>((it) {
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
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showDetails(context, d),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    child: Row(
                      children: [
                        // Leading short order id
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[200],
                          child: Text(
                            d.id.substring(0, 4).toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Main info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d['customerName'] ?? 'Customer',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'Total: \$${(d['total'] ?? 0).toString()}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 12),
                                  _StatusChip(status: status),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Animated status button
                        _AnimatedStatusButton(
                          initialStatus: status,
                          onStatusSelected: (s) async {
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
                                      content:
                                          Text('Failed to update status: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
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

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  Color _colorFor(OrderStatus s) {
    if (s == OrderStatus.cancelled) return Colors.red;
    if (s == OrderStatus.delivered) return Colors.green;
    if (s == OrderStatus.processing) return Colors.orange;
    if (s == OrderStatus.shipped) return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    return Chip(
      label: Text(status.name,
          style: TextStyle(
              color: color.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white)),
      backgroundColor: color.withOpacity(0.15),
      avatar: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.local_shipping, size: 16, color: color)),
    );
  }
}

/// Small animated status button that shows a bus icon when tapped and
/// presents a menu to change status. Calls `onStatusSelected` after user
/// selects a new status.
class _AnimatedStatusButton extends StatefulWidget {
  final OrderStatus initialStatus;
  final Future<void> Function(OrderStatus) onStatusSelected;

  const _AnimatedStatusButton({
    required this.initialStatus,
    required this.onStatusSelected,
  });

  @override
  State<_AnimatedStatusButton> createState() => _AnimatedStatusButtonState();
}

class _AnimatedStatusButtonState extends State<_AnimatedStatusButton>
    with SingleTickerProviderStateMixin {
  late OrderStatus _status;
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _colorFor(OrderStatus s) {
    if (s == OrderStatus.cancelled) return Colors.red;
    if (s == OrderStatus.delivered) return Colors.green;
    if (s == OrderStatus.processing) return Colors.orange;
    if (s == OrderStatus.shipped) return Colors.blue;
    return Colors.grey;
  }

  Future<void> _onTap(BuildContext context) async {
    // brief bounce animation
    await _ctrl.forward();
    await _ctrl.reverse();

    // show menu anchored to this widget
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final result = await showMenu<OrderStatus>(
      context: context,
      position: RelativeRect.fromLTRB(
          offset.dx, offset.dy, offset.dx + renderBox.size.width, offset.dy),
      items: OrderStatus.values
          .map((s) => PopupMenuItem(value: s, child: Text(s.name)))
          .toList(),
    );

    if (result != null) {
      setState(() => _status = result);
      await widget.onStatusSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(_status);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _onTap(context),
          child: ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.15).animate(
                CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack)),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_bus, size: 18, color: color),
                  const SizedBox(width: 6),
                  Text(
                    _status.name,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
