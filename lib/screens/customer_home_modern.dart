import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'menu_browse_screen.dart';
import 'location_screen.dart';
import 'review_order.dart';
import 'order_placed.dart';
import 'order_history_screen.dart';
import '../services/reward_points.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';

/// Modern customer home screen with a hero section, featured items,
/// and quick action buttons
class CustomerHomeModern extends StatefulWidget {
  const CustomerHomeModern({super.key});

  @override
  State<CustomerHomeModern> createState() => _CustomerHomeModernState();
}

class _CustomerHomeModernState extends State<CustomerHomeModern> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, int> _cart = {};
  // migrated to AppState for real-time sync across screens
  // keep a default but store centrally
  String? _selectedLocation;
  int _rewardsPoints = 0;

  @override
  void initState() {
    super.initState();
    _selectedLocation = 'Barton Rd Stell'; // default location
    AppState.instance.setLocation(_selectedLocation);
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final pts = await RewardPoints.instance.getPoints(user.email ?? '');
      if (!mounted) return;
      setState(() => _rewardsPoints = pts);
    } catch (_) {
      // ignore errors for now
    }
  }

  void _addToCart(String teaId) {
    setState(() {
      _cart[teaId] = (_cart[teaId] ?? 0) + 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to cart'),
        duration: Duration(seconds: 1),
      ),
    );
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

  Future<void> _placeOrder(Map<String, Map<String, dynamic>> teaData) async {
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
      final pickup = AppState.instance.selectedPickup.value;
      await _db.collection('orders').add({
        'customerName': user?.email ?? 'Guest',
        'customerId': user?.uid,
        'total': total,
        'status': 'pending',
        'location':
            AppState.instance.selectedLocation.value ?? _selectedLocation,
        if (pickup != null) 'pickupAt': Timestamp.fromDate(pickup),
        'createdAt': FieldValue.serverTimestamp(),
        'items': items,
      });

      if (!mounted) return;
      setState(() => _cart.clear());

      // Navigate to order placed screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrderPlacedScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    }
  }

  void _showItemDetails(Map<String, dynamic> item, String itemId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemDetailsSheet(
        item: item,
        itemId: itemId,
        onAddToCart: () => _addToCart(itemId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4DB5BD); // Teal/cyan from screenshots

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jivan Swad Tea',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: AppState.instance.selectedLocation,
              builder: (_, loc, __) => Text(
                loc ?? _selectedLocation ?? 'Select location',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ),
            ValueListenableBuilder<DateTime?>(
              valueListenable: AppState.instance.selectedPickup,
              builder: (_, dt, __) => Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  dt == null ? '' : DateFormat.yMMMd().add_jm().format(dt),
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on, color: Colors.black87),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LocationScreen(
                    currentLocation: _selectedLocation,
                  ),
                ),
              );
              if (result != null) {
                setState(() => _selectedLocation = result);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black87),
            onPressed: () async {
              final user = _auth.currentUser;
              if (user == null) {
                // Not logged in, go to auth screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              } else {
                // Logged in, show profile menu
                await AuthService.logout();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('teas').orderBy('name').snapshots(),
        builder: (context, snap) {
          // Build tea data map
          final teaData = <String, Map<String, dynamic>>{};
          List<Map<String, dynamic>> allTeas = [];

          if (snap.hasData && snap.data!.docs.isNotEmpty) {
            for (var d in snap.data!.docs) {
              final data = Map<String, dynamic>.from(d.data() as Map);
              data['id'] = d.id;
              teaData[d.id] = data;
              allTeas.add(data);
            }
          } else {
            // Demo data
            final demoDocs = [
              {
                'id': 'a',
                'name': 'Tulsi Honey Chai',
                'price': 5.25,
                'description': 'Aromatic tulsi chai sweetened with honey',
                'category': 'Tea'
              },
              {
                'id': 'b',
                'name': 'Masala Chai',
                'price': 4.75,
                'description':
                    'Traditional Indian spiced tea with aromatic spices',
                'category': 'Tea'
              },
              {
                'id': 'c',
                'name': 'Matcha Green Tea',
                'price': 5.50,
                'description': 'Smooth matcha green tea',
                'category': 'Tea'
              },
            ];
            for (var d in demoDocs) {
              teaData[d['id'] as String] = d;
              allTeas.add(d);
            }
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero banner
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor.withOpacity(0.1), Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stay up to date and\norder your favorites',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MenuBrowseScreen(
                                      cart: _cart,
                                      onAddToCart: _addToCart,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Order Now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Rewards quick card
                          if (_rewardsPoints > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Rewards',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.black54)),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${(_rewardsPoints / 100).toStringAsFixed(2)} USD • ${_rewardsPoints} pts',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87)),
                                ],
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OrderHistoryScreen(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: BorderSide(color: primaryColor),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Orders',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Featured items
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Featured Items',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: allTeas.length > 4 ? 4 : allTeas.length,
                        itemBuilder: (context, i) {
                          final item = allTeas[i];
                          final id = item['id'] as String;
                          final price = (item['price'] ?? 0).toDouble();
                          final inCart = _cart[id] ?? 0;

                          return GestureDetector(
                            onTap: () => _showItemDetails(item, id),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.emoji_food_beverage,
                                          size: 48,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] ?? 'Tea',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '\$${price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (inCart > 0)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: primaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'x$inCart',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.restaurant_menu),
                if (_cart.isNotEmpty)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_cart.values.fold<int>(0, (a, b) => a + b)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Menu',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Sign In',
          ),
        ],
        onTap: (index) async {
          if (index == 1) {
            // Menu
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MenuBrowseScreen(
                  cart: _cart,
                  onAddToCart: _addToCart,
                ),
              ),
            );
            setState(() {}); // Refresh cart badge
          } else if (index == 2) {
            final user = _auth.currentUser;
            if (user == null) {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
              // After potential login, refresh rewards
              await _loadRewards();
            } else {
              // Logged in, show profile dialog
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Account'),
                  content: Text('Signed in as: ${user.email ?? "Guest"}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await AuthService.logout();
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                        // cleared login — reset rewards
                        setState(() => _rewardsPoints = 0);
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            }
          }
        },
      ),
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: primaryColor,
              onPressed: () => _showCartDialog(),
              icon: const Icon(Icons.shopping_cart),
              label:
                  Text('Cart (${_cart.values.fold<int>(0, (a, b) => a + b)})'),
            )
          : null,
    );
  }

  Future<void> _showCartDialog() async {
    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    Map<String, Map<String, dynamic>> teaData = {};

    try {
      final docs = await _db.collection('teas').get();
      for (var d in docs.docs) {
        teaData[d.id] = Map<String, dynamic>.from(d.data() as Map);
      }
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains('permission-denied') ||
          err.contains('permission denied')) {
        // Use demo data
        final demoDocs = [
          {'id': 'a', 'name': 'Tulsi Honey Chai', 'price': 5.25},
          {'id': 'b', 'name': 'Masala Chai', 'price': 4.75},
          {'id': 'c', 'name': 'Matcha Green Tea', 'price': 5.50},
        ];
        for (var d in demoDocs) {
          teaData[d['id'] as String] = d;
        }
      } else {
        if (!mounted) return;
        scaffold.showSnackBar(
          SnackBar(content: Text('Failed to load items for cart: $e')),
        );
        return;
      }
    }

    navigator.push(
      PageRouteBuilder(
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
                        'Qty: ${e.value} • \$${(price * e.value).toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              _removeFromCart(e.key);
                              navigator.pop();
                              _showCartDialog(); // Refresh
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    'Total: \$${_calculateTotal(teaData).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => navigator.pop(),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    navigator.pop(); // Close cart dialog

                    // Build order items for review
                    final user = _auth.currentUser;
                    final orderItems = _cart.entries.map((e) {
                      final tea = teaData[e.key];
                      final name = tea?['name'] ?? 'Tea';
                      final price = (tea?['price'] ?? 0).toDouble();
                      return OrderItem(
                        name: name.toString(),
                        priceCents: (price * 100).toInt(),
                        qty: e.value,
                      );
                    }).toList();

                    // Navigate to review order screen
                    navigator
                        .push(
                      MaterialPageRoute(
                        builder: (_) => ReviewOrderScreen(
                          args: ReviewOrderArgs(
                            customerName:
                                user?.displayName ?? user?.email ?? 'Guest',
                            customerEmail: user?.email ?? '',
                            customerPhone:
                                '', // Could add phone to user profile
                            items: orderItems,
                            rewardsPoints: _rewardsPoints,
                          ),
                        ),
                      ),
                    )
                        .then((success) {
                      // If payment was successful, place the order
                      if (success == true && mounted) {
                        _placeOrder(teaData);
                      }
                    });
                  },
                  child: const Text('Checkout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Item details bottom sheet
class ItemDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final String itemId;
  final VoidCallback onAddToCart;

  const ItemDetailsSheet({
    super.key,
    required this.item,
    required this.itemId,
    required this.onAddToCart,
  });

  @override
  State<ItemDetailsSheet> createState() => _ItemDetailsSheetState();
}

class _ItemDetailsSheetState extends State<ItemDetailsSheet> {
  int _quantity = 1;
  String? _selectedSize;

  final List<Map<String, dynamic>> _sizes = [
    {'name': '8oz Hot', 'price': 5.25},
    {'name': '12oz Hot', 'price': 5.75},
    {'name': '12oz Iced', 'price': 5.75},
    {'name': '16oz Hot', 'price': 6.25},
    {'name': '16oz Iced', 'price': 6.25},
    {'name': '24oz Hot', 'price': 7.75},
    {'name': '24oz Iced', 'price': 7.75},
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4DB5BD);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.item['name'] ?? 'Tea',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.item['description'] ?? 'Delicious tea',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),

            // Quantity selector
            Row(
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.remove, size: 20),
                  ),
                  onPressed: () {
                    if (_quantity > 1) {
                      setState(() => _quantity--);
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    setState(() => _quantity++);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Size selector
            const Text(
              'Size',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Required',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),

            ..._sizes.map((size) {
              final isSelected = _selectedSize == size['name'];
              return RadioListTile<String>(
                value: size['name'] as String,
                groupValue: _selectedSize,
                onChanged: (val) => setState(() => _selectedSize = val),
                title: Text(size['name'] as String),
                subtitle:
                    Text('\$${(size['price'] as double).toStringAsFixed(2)}'),
                activeColor: primaryColor,
                selected: isSelected,
              );
            }),

            const SizedBox(height: 24),

            // Add to cart button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  for (int i = 0; i < _quantity; i++) {
                    widget.onAddToCart();
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
