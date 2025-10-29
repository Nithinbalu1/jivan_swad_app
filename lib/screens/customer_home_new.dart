import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, int> _cart = {};

  void _addToCart(String teaId) {
    setState(() {
      _cart[teaId] = (_cart[teaId] ?? 0) + 1;
    });
  }

  void _removeFromCart(String teaId) {
    setState(() {
      final q = (_cart[teaId] ?? 0) - 1;
      if (q <= 0) {
        _cart.remove(teaId);
      } else {
        _cart[teaId] = q;
      }
    });
  }

  double _calculateTotal(Map<String, Map<String, dynamic>> teaData) {
    double total = 0.0;
    _cart.forEach((id, qty) {
      final tea = teaData[id];
      if (tea != null) {
        final price = (tea['price'] ?? 0).toDouble();
        total += price * qty;
      }
    });
    return total;
  }

  Future<void> _placeOrder(Map<String, Map<String, dynamic>> teaData,
      {bool simulate = false}) async {
    if (_cart.isEmpty) return;
    final user = _auth.currentUser;
    final items = <Map<String, dynamic>>[];
    double total = 0.0;
    _cart.forEach((id, qty) {
      final tea = teaData[id];
      final name = tea?['name'] ?? 'Tea';
      final price = (tea?['price'] ?? 0).toDouble();
      items.add({'teaId': id, 'name': name, 'qty': qty, 'price': price});
      total += price * qty;
    });

    try {
      if (simulate) {
        // Demo/simulated mode: do not write to Firestore
        if (!mounted) return;
        setState(() => _cart.clear());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Demo order placed (not sent to server)')));
      } else {
        await _db.collection('orders').add({
          'customerName': user?.email ?? 'Guest',
          'total': total,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'items': items,
        });

        if (!mounted) return;
        setState(() => _cart.clear());
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order placed successfully')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final teasStream = _db.collection('teas').orderBy('name').snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Home'),
        actions: [
          IconButton(
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${user?.email ?? 'Customer'}!',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Available Items', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: teasStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());

                  // If there's a permission error, offer a small demo list (A/B/C)
                  final errString = snap.error?.toString() ?? '';
                  final isPermissionDenied =
                      errString.toLowerCase().contains('permission-denied') ||
                          errString.toLowerCase().contains('permission denied');
                  if (snap.hasError && isPermissionDenied) {
                    // Demo items: simple map of id -> data
                    final demoDocs = [
                      {
                        'id': 'a',
                        'name': 'A Tea',
                        'price': 49.0,
                        'description': 'Sample A tea (demo)'
                      },
                      {
                        'id': 'b',
                        'name': 'B Tea',
                        'price': 59.0,
                        'description': 'Sample B tea (demo)'
                      },
                      {
                        'id': 'c',
                        'name': 'C Tea',
                        'price': 69.0,
                        'description': 'Sample C tea (demo)'
                      },
                    ];

                    // Build a map for lookups
                    final teaData = <String, Map<String, dynamic>>{};
                    for (var d in demoDocs) {
                      teaData[d['id'] as String] = {
                        'name': d['name'],
                        'price': d['price'],
                        'description': d['description'],
                      };
                    }

                    return Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                              'Running in demo mode — Firestore permissions denied',
                              style: TextStyle(color: Colors.orange)),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: demoDocs.length,
                            itemBuilder: (context, i) {
                              final data = demoDocs[i];
                              final id = data['id'] as String;
                              final price = (data['price'] as num).toDouble();
                              final inCart = _cart[id] ?? 0;
                              return Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                      child: Icon(Icons.local_cafe)),
                                  title: Text(data['name'] as String),
                                  subtitle: Text(
                                      '\$${price.toStringAsFixed(2)} (demo)'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (inCart > 0) Text('x$inCart'),
                                      IconButton(
                                        icon:
                                            const Icon(Icons.add_shopping_cart),
                                        onPressed: () => _addToCart(id),
                                      ),
                                    ],
                                  ),
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text(data['name'] as String),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(data['description'] as String),
                                          const SizedBox(height: 8),
                                          Text(
                                              'Price: \$${price.toStringAsFixed(2)}'),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Close')),
                                        ElevatedButton(
                                            onPressed: () {
                                              _addToCart(id);
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Add')),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  if (snap.hasError)
                    return Center(
                        child: Text('Error loading items: ${snap.error}'));
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty)
                    return const Center(
                        child: Text('No items available right now.'));

                  // Build a map of tea data for quick lookup
                  final teaData = <String, Map<String, dynamic>>{};
                  for (var d in docs) {
                    teaData[d.id] = Map<String, dynamic>.from(d.data() as Map);
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final d = docs[i];
                      final data = Map<String, dynamic>.from(d.data() as Map);
                      final price = (data['price'] ?? 0).toDouble();
                      final inCart = _cart[d.id] ?? 0;
                      return Card(
                        child: ListTile(
                          leading: data['imageUrl'] != null &&
                                  data['imageUrl'].toString().isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(data['imageUrl']))
                              : const CircleAvatar(
                                  child: Icon(Icons.local_cafe)),
                          title: Text(data['name'] ?? 'Tea'),
                          subtitle: Text('\$${price.toStringAsFixed(2)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (inCart > 0) Text('x$inCart'),
                              IconButton(
                                icon: const Icon(Icons.add_shopping_cart),
                                onPressed: () => _addToCart(d.id),
                              ),
                            ],
                          ),
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(data['name'] ?? 'Tea'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['description'] ?? ''),
                                  const SizedBox(height: 8),
                                  Text('Price: \$${price.toStringAsFixed(2)}'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close')),
                                ElevatedButton(
                                    onPressed: () {
                                      _addToCart(d.id);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Add')),
                              ],
                            ),
                          ),
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
      floatingActionButton: FloatingActionButton.extended(
        label: Text('Cart (${_cart.values.fold<int>(0, (a, b) => a + b)})'),
        icon: const Icon(Icons.shopping_cart),
        onPressed: () async {
          // Try to build teaData map from Firestore; if permission denied, fall back to demo items
          Map<String, Map<String, dynamic>> teaData = {};
          bool demoMode = false;
          try {
            final docs = await _db.collection('teas').get();
            for (var d in docs.docs) {
              teaData[d.id] = Map<String, dynamic>.from(d.data() as Map);
            }
          } catch (e) {
            final err = e.toString().toLowerCase();
            if (err.contains('permission-denied') ||
                err.contains('permission denied')) {
              demoMode = true;
              final demoDocs = [
                {
                  'id': 'a',
                  'name': 'A Tea',
                  'price': 49.0,
                  'description': 'Sample A tea (demo)'
                },
                {
                  'id': 'b',
                  'name': 'B Tea',
                  'price': 59.0,
                  'description': 'Sample B tea (demo)'
                },
                {
                  'id': 'c',
                  'name': 'C Tea',
                  'price': 69.0,
                  'description': 'Sample C tea (demo)'
                },
              ];
              for (var d in demoDocs) {
                teaData[d['id'] as String] = {
                  'name': d['name'],
                  'price': d['price'],
                  'description': d['description'],
                };
              }
            } else {
              // other error: show it
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load items for cart: $e')));
              return;
            }
          }

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Your Cart'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_cart.isEmpty) const Text('Your cart is empty.'),
                  ..._cart.entries.map((e) {
                    final tea = teaData[e.key];
                    final name = tea?['name'] ?? 'Tea';
                    final price = (tea?['price'] ?? 0).toDouble();
                    return ListTile(
                      title: Text(name.toString()),
                      subtitle: Text(
                          'Qty: ${e.value} • \$${(price * e.value).toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                _removeFromCart(e.key);
                                Navigator.pop(context);
                              }),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  Text(
                      'Total: \$${_calculateTotal(teaData).toStringAsFixed(2)}'),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close')),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _placeOrder(teaData, simulate: demoMode);
                    },
                    child: const Text('Place Order')),
              ],
            ),
          );
        },
      ),
    );
  }
}
