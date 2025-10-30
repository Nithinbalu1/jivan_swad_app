import 'package:flutter/material.dart';

/// A small, local AI assistant UI with a searchable FAQ and a tiny
/// recommendation engine that works from available items and the cart.

class AIAssistantScreen extends StatefulWidget {
  /// The list of available items. Each item is a Map with keys like
  /// 'id', 'name', 'price', 'description'. If empty, assistant will use
  /// a small built-in demo list.
  final List<Map<String, dynamic>> items;

  /// The user's current cart mapping teaId -> qty. Used to produce
  /// personalized recommendations.
  final Map<String, int> cart;

  const AIAssistantScreen({super.key, required this.items, required this.cart});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _search = TextEditingController();

  final List<Map<String, String>> _faq = [
    {
      'q': 'How do I place an order?',
      'a':
          'Add items to the cart, open the cart and tap Place Order. You will be guided through payment.'
    },
    {
      'q': 'Can I cancel an order?',
      'a':
          'Orders can be cancelled from the provider dashboard when they are still pending. Contact support for faster help.'
    },
    {
      'q': 'How do I add new items (admin)?',
      'a':
          'Admins can go to Manage Teas in the provider area and tap Add to create new items.'
    },
    {
      'q': 'Why am I seeing demo items?',
      'a':
          'Demo items appear when the app cannot read from Firestore (e.g., emulator not running or Firestore rules prevent reads).'
    },
  ];

  List<Map<String, dynamic>> get _items => widget.items.isNotEmpty
      ? widget.items
      : [
          {'id': 'a', 'name': 'A Tea', 'price': 49.0, 'description': 'Demo A'},
          {'id': 'b', 'name': 'B Tea', 'price': 59.0, 'description': 'Demo B'},
          {'id': 'c', 'name': 'C Tea', 'price': 69.0, 'description': 'Demo C'},
        ];

  List<Map<String, dynamic>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _buildRecommendations();
  }

  void _buildRecommendations() {
    final items = _items;
    final cartIds = widget.cart.keys.toSet();

    // Simple heuristic: if cart has items, try to find items that share a
    // word in the name; otherwise recommend the cheapest items not in cart.
    final List<Map<String, dynamic>> recs = [];

    if (cartIds.isNotEmpty) {
      final cartNames = <String>[];
      for (var id in cartIds) {
        final found = items.firstWhere((it) => it['id'] == id,
            orElse: () => <String, dynamic>{});
        if ((found['name'] ?? '').toString().isNotEmpty) {
          cartNames.add(found['name'].toString());
        }
      }

      final words = cartNames
          .expand((n) => n.split(RegExp(r'\s+')))
          .map((s) => s.toLowerCase())
          .where((s) => s.length > 2)
          .toSet();

      for (var it in items) {
        if (cartIds.contains(it['id'])) continue;
        final name = (it['name'] ?? '').toString().toLowerCase();
        final match = words.any((w) => name.contains(w));
        if (match) recs.add(it);
      }
    }

    if (recs.isEmpty) {
      // fallback: cheapest items not in cart
      final fallback = List<Map<String, dynamic>>.from(items)
        ..removeWhere((it) => widget.cart.containsKey(it['id']))
        ..sort((a, b) {
          final pa = (a['price'] ?? double.infinity) as num;
          final pb = (b['price'] ?? double.infinity) as num;
          return pa.compareTo(pb);
        });
      recs.addAll(fallback.take(3));
    }

    _recommendations = recs;
  }

  List<Map<String, String>> get _filteredFaq {
    final q = _search.text.toLowerCase().trim();
    if (q.isEmpty) return _faq;
    return _faq.where((f) {
      return f['q']!.toLowerCase().contains(q) ||
          f['a']!.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search FAQ or ask a question',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  const Text('FAQ',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._filteredFaq.map((f) => Card(
                        child: ListTile(
                          title: Text(f['q']!),
                          subtitle: Text(f['a']!),
                        ),
                      )),
                  const SizedBox(height: 16),
                  const Text('Recommended for you',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._recommendations.map((it) => Card(
                        child: ListTile(
                          title: Text(it['name'] ?? 'Item'),
                          subtitle: Text(it['description']?.toString() ?? ''),
                          trailing: Text('\$${(it['price'] ?? 0).toString()}'),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
