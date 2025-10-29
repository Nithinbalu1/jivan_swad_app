// lib/provider/analytics.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  double revenue = 0.0;
  Map<String, int> teaCounts = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => loading = true);
    final ordersSnap =
        await FirebaseFirestore.instance.collection('orders').get();
    double r = 0.0;
    final Map<String, int> counts = {};
    for (var doc in ordersSnap.docs) {
      final data = doc.data();
      // Safely parse total (could be int/double/null)
      final totalVal = data['total'];
      if (totalVal is num) {
        r += totalVal.toDouble();
      } else if (totalVal is String) {
        r += double.tryParse(totalVal) ?? 0.0;
      }

      // Items in orders may be stored as a List or as a Map; handle both.
      final itemsRaw = data['items'];
      List items = [];
      if (itemsRaw is Iterable) {
        items = List.from(itemsRaw);
      } else if (itemsRaw is Map) {
        // If items stored as a map, take its values
        items = List.from(itemsRaw.values);
      }

      for (var it in items) {
        if (it is! Map) continue;
        final id = it['teaId'] ?? it['id'] ?? it['name'] ?? 'unknown';
        final qtyVal = it['qty'] ?? 0;
        final qty = int.tryParse(qtyVal.toString()) ?? 0;
        counts[id.toString()] = (counts[id.toString()] ?? 0) + qty;
      }
    }
    setState(() {
      revenue = r;
      teaCounts = counts;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sorted = teaCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total revenue: \$${revenue.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Top teas (by qty sold):',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (sorted.isEmpty)
                    const Text('No sales yet.')
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: sorted.length,
                        itemBuilder: (context, i) {
                          final e = sorted[i];
                          return ListTile(
                            leading: CircleAvatar(child: Text('${i + 1}')),
                            title: Text(e.key.toString()),
                            trailing: Text('Sold: ${e.value}'),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
