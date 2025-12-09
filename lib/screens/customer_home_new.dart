import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/payment_simulator.dart';
import 'ai_assistant.dart';
import 'auth_screen.dart';
import 'order_history_screen.dart';

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
      {bool simulate = false, NavigatorState? navigator}) async {
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('order placed ')));
        // In demo mode also navigate to order history so user sees the result
        final navToUse = navigator ?? Navigator.of(context);
        // ignore: avoid_print
        print('Demo mode: navigating to OrderHistoryScreen');
        navToUse.pushReplacement(
          MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
        );
      } else {
        // Estimate wait time and include metadata similar to other flows
        final totalQty = items.fold<int>(0, (s, it) => s + (it['qty'] as int));
        final estMinutes = (10 + (2 * totalQty)).clamp(5, 120);

        final docRef = await _db.collection('orders').add({
          'customerName': user?.email ?? 'Guest',
          'customerId': user?.uid,
          'total': total,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'estimatedWaitMinutes': estMinutes,
          'items': items,
        });

        // Debug: log the created order id so we can trace in logs
        // (useful when Firestore rules silently reject writes or succeed)
        // ignore: avoid_print
        print('Order created: ${docRef.id}');

        if (!mounted) return;
        setState(() => _cart.clear());

        // Debug: log before navigating so we can verify navigation intent
        // ignore: avoid_print
        print('Navigating to OrderHistoryScreen (replace stack)');

        // Navigate to order history so user can see their order and wait time.
        // Use pushAndRemoveUntil to ensure a consistent UX even when nested
        // dialogs or alternative navigator states are in use.
        final navToUse = navigator ?? Navigator.of(context);
        navToUse.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Log full error to console to help debugging
      // ignore: avoid_print
      print('Failed to place order: $e');
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
            tooltip: 'Assistant',
            onPressed: () async {
              // Capture navigator before async work to avoid using BuildContext
              // across an async gap (silences analyzer warning).
              final navigator = Navigator.of(context);

              // Try to fetch items for recommendations; fall back to demo
              List<Map<String, dynamic>> items = [];
              try {
                final docs = await _db.collection('teas').get();
                for (var d in docs.docs) {
                  final m = Map<String, dynamic>.from(d.data() as Map);
                  m['id'] = d.id;
                  items.add(m);
                }
              } catch (_) {
                // ignore and let assistant use demo items
              }

              if (!mounted) return;
              navigator.push(
                MaterialPageRoute(
                    builder: (_) => AIAssistantScreen(
                        items: items,
                        cart: _cart,
                        onAddToCart: (id) => _addToCart(id))),
              );
            },
            icon: const Icon(Icons.smart_toy_outlined),
          ),
          IconButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await AuthService.logout();
              if (!mounted) return;
              navigator.pushReplacement(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
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
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

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
                          child: Text('Menu',
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
                                      child: Icon(Icons.emoji_food_beverage)),
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

                  if (snap.hasError) {
                    return Center(
                        child: Text('Error loading items: ${snap.error}'));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    // If there are no items in Firestore, show a small demo set
                    // so the customer UI isn't empty during local/dev runs.
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
                          child: Text('Menu items',
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
                                      child: Icon(Icons.emoji_food_beverage)),
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
                                  child: Icon(Icons.emoji_food_beverage)),
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
          // Build tea data; fall back to demo items if permission denied.
          final navigator = Navigator.of(context);
          final scaffold = ScaffoldMessenger.of(context);

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
              if (!mounted) return;
              scaffold.showSnackBar(
                  SnackBar(content: Text('Failed to load items for cart: $e')));
              return;
            }
          }

          // Show cart dialog using the captured navigator so we don't use the
          // widget BuildContext inside an async function (avoids analyzer
          // use_build_context_synchronously warnings).
          navigator.push(PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => Center(
              child: Material(
                type: MaterialType.transparency,
                child: AlertDialog(
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
                                    navigator.pop();
                                  }),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Text(
                          'Total: \$${_calculateTotal(teaData).toStringAsFixed(2)}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => navigator.pop(),
                        child: const Text('Close')),
                    ElevatedButton(
                        onPressed: () async {
                          // close the cart dialog
                          navigator.pop();

                          final total = _calculateTotal(teaData);

                          // show progress using the captured navigator (avoid using
                          // the widget BuildContext across the async gap)
                          navigator.push(PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (_, __, ___) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ));

                          final result =
                              await PaymentSimulator.processPayment(total);

                          if (!mounted) return;
                          navigator.pop(); // remove progress route

                          if (!result.success) {
                            scaffold.showSnackBar(SnackBar(
                                content:
                                    Text('Payment failed: ${result.message}')));
                            return;
                          }

                          // Pass the captured navigator so _placeOrder can
                          // perform navigation on the same navigator used for
                          // dialog/progress routes.
                          await _placeOrder(teaData,
                              simulate: demoMode, navigator: navigator);
                        },
                        child: const Text('Place Order')),
                  ],
                ),
              ),
            ),
          ));
        },
      ),
    );
  }
}
