import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import 'location_screen.dart';
import 'package:flutter/material.dart';
import 'review_order.dart';

/// Browse menu screen with categories and filters
class MenuBrowseScreen extends StatefulWidget {
  final Map<String, int> cart;
  final Function(String) onAddToCart;

  const MenuBrowseScreen({
    super.key,
    required this.cart,
    required this.onAddToCart,
  });

  @override
  State<MenuBrowseScreen> createState() => _MenuBrowseScreenState();
}

class _MenuBrowseScreenState extends State<MenuBrowseScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Categories removed per request; show full menu list.

  void _showItemDetails(Map<String, dynamic> item, String itemId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemDetailsSheet(
        item: item,
        itemId: itemId,
        onAddToCart: () => widget.onAddToCart(itemId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4DB5BD);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Browse the menu and\nplace an order',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            height: 1.2,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location and time selection
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place, size: 20),
                    const SizedBox(width: 8),
                    const Text('Ordering from: ',
                        style: TextStyle(fontSize: 14)),
                    ValueListenableBuilder<String?>(
                      valueListenable: AppState.instance.selectedLocation,
                      builder: (_, loc, __) {
                        final label = loc ?? 'Select location';
                        return GestureDetector(
                          onTap: () async {
                            // Open the LocationScreen (same pattern used elsewhere)
                            final res = await Navigator.push<String?>(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => LocationScreen(
                                        currentLocation: loc,
                                      )),
                            );
                            if (res != null) AppState.instance.setLocation(res);
                          },
                          child: Text(label,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor)),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          // Pick date then time
                          final now = DateTime.now();
                          final d = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 30)));
                          if (d == null) return;
                          final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(now));
                          if (t == null) return;
                          final dt = DateTime(
                              d.year, d.month, d.day, t.hour, t.minute);
                          AppState.instance.setPickup(dt);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ValueListenableBuilder<DateTime?>(
                            valueListenable: AppState.instance.selectedPickup,
                            builder: (_, dt, __) {
                              final label = dt == null
                                  ? 'Pick date & time'
                                  : DateFormat.yMMMd().add_jm().format(dt);
                              return Text(label);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Categories removed: show full menu directly

          // Items list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('teas').orderBy('name').snapshots(),
              builder: (context, snap) {
                List<Map<String, dynamic>> allTeas = [];

                if (snap.hasData && snap.data!.docs.isNotEmpty) {
                  for (var d in snap.data!.docs) {
                    final data = Map<String, dynamic>.from(d.data() as Map);
                    data['id'] = d.id;
                    allTeas.add(data);
                  }
                } else {
                  // Demo data
                  allTeas = [
                    {
                      'id': 'a',
                      'name': 'Tulsi Honey Chai',
                      'price': 5.25,
                      'description':
                          'Aromatic tulsi (holy basil) chai sweetened with honey',
                      'category': 'Tea'
                    },
                    {
                      'id': 'b',
                      'name': 'Bacon, Avocado Egg & Cheese',
                      'price': 9.42,
                      'description':
                          'Bacon, avocado, hard-boiled egg & cheddar cheese',
                      'category': 'Breakfast'
                    },
                    {
                      'id': 'c',
                      'name': 'Lemongrass Green',
                      'price': 5.75,
                      'description':
                          'Fresh lemongrass and steamed green tea blend',
                      'category': 'Tea'
                    },
                    {
                      'id': 'd',
                      'name': 'Classic Assam',
                      'price': 3.25,
                      'description': 'Robust Assam black tea served hot',
                      'category': 'Tea'
                    },
                  ];
                }

                // No category filtering: show all items

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Featured Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...allTeas.map((item) {
                      final id = item['id'] as String;
                      final price = (item['price'] ?? 0).toDouble();
                      final inCart = widget.cart[id] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _showItemDetails(item, id),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'] ?? 'Tea',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item['description'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '\$${price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Stack(
                                      children: [
                                        // Square product image (uses `imageUrl` if present)
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: (item['imageUrl'] != null &&
                                                    (item['imageUrl'] as String)
                                                        .isNotEmpty)
                                                ? Image.network(
                                                    item['imageUrl'] as String,
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (context, error, st) =>
                                                            Center(
                                                      child: Icon(
                                                        Icons
                                                            .emoji_food_beverage,
                                                        size: 32,
                                                        color: primaryColor,
                                                      ),
                                                    ),
                                                    loadingBuilder:
                                                        (context, child, prog) {
                                                      if (prog == null)
                                                        return child;
                                                      return const Center(
                                                          child:
                                                              CircularProgressIndicator());
                                                    },
                                                  )
                                                : Center(
                                                    child: Icon(
                                                      Icons.emoji_food_beverage,
                                                      size: 32,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        if (inCart > 0)
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '$inCart',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                // Build items list by querying Firestore for current prices/names
                final teaData = <String, Map<String, dynamic>>{};
                try {
                  final docs =
                      await FirebaseFirestore.instance.collection('teas').get();
                  for (var d in docs.docs) {
                    final m = Map<String, dynamic>.from(d.data() as Map);
                    m['id'] = d.id;
                    teaData[d.id] = m;
                  }
                } catch (_) {
                  // ignore and allow demo fallback in ReviewOrder
                }

                // Compose order items
                final items = <OrderItem>[];
                widget.cart.forEach((id, qty) {
                  final tea = teaData[id];
                  final name = tea != null ? tea['name'].toString() : id;
                  final price = tea != null
                      ? ((tea['price'] ?? 0.0) as num).toDouble()
                      : 0.0;
                  items.add(OrderItem(
                      name: name, priceCents: (price * 100).round(), qty: qty));
                });

                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewOrderScreen(
                      args: ReviewOrderArgs(
                        customerName: 'Guest',
                        customerEmail: '',
                        customerPhone: '',
                        items: items,
                        rewardsPoints: 0,
                      ),
                    ),
                  ),
                );
              },
              heroTag: 'cart_fab',
              label: Text(
                  '${widget.cart.values.fold<int>(0, (s, v) => s + v)} • View Cart'),
              icon: const Icon(Icons.shopping_cart),
            )
          : null,
    );
  }
}

/// Item details bottom sheet (reused from customer_home_modern)
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

  final List<Map<String, dynamic>> _sizes = [];

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
              '',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '',
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
