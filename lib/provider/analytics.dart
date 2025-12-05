// lib/provider/analytics.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  double revenue = 0.0;
  Map<String, int> teaCounts = {};
  Map<String, String> teaNames = {};
  Map<String, double> last7 = {};
  List<String> last7Labels = [];
  bool loading = true;
  int totalOrders = 0;
  int totalItemsSold = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => loading = true);
    // fetch tea names to display human-friendly labels
    try {
      final teasSnap =
          await FirebaseFirestore.instance.collection('teas').get();
      final Map<String, String> names = {};
      for (var d in teasSnap.docs) {
        final data = d.data();
        final n = (data['name'] ?? d.id).toString();
        names[d.id] = n;
      }
      teaNames = names;
    } catch (_) {
      // ignore errors — we'll fall back to ids
      teaNames = {};
    }
    final ordersSnap = await FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .get();

    // Prepare last 7 days labels
    final now = DateTime.now();
    last7 = {};
    last7Labels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final label = DateFormat('EEE').format(d); // Mon, Tue, etc.
      last7[label] = 0.0;
      return label;
    });

    double r = 0.0;
    final Map<String, int> counts = {};
    int itemsTotal = 0;

    for (var doc in ordersSnap.docs) {
      final data = doc.data();

      // Safely parse total (could be int/double/null)
      double orderTotal = 0.0;
      final totalVal = data['total'];
      if (totalVal is num) {
        orderTotal = totalVal.toDouble();
      } else if (totalVal is String) {
        orderTotal = double.tryParse(totalVal) ?? 0.0;
      }
      r += orderTotal;

      // createdAt handling (Timestamp or millis)
      DateTime created = DateTime.now();
      try {
        final ca = data['createdAt'];
        if (ca is Timestamp) {
          created = ca.toDate();
        } else if (ca is int) {
          created = DateTime.fromMillisecondsSinceEpoch(ca);
        }
      } catch (_) {}

      final label = DateFormat('EEE').format(created);
      if (last7.containsKey(label)) {
        last7[label] = last7[label]! + orderTotal;
      }

      // Items in orders may be stored as a List or as a Map; handle both.
      final itemsRaw = data['items'];
      List items = [];
      if (itemsRaw is Iterable) {
        items = List.from(itemsRaw);
      } else if (itemsRaw is Map) {
        items = List.from(itemsRaw.values);
      }

      for (var it in items) {
        if (it is! Map) continue;
        final id = it['teaId'] ?? it['id'] ?? it['name'] ?? 'unknown';
        final qtyVal = it['qty'] ?? 0;
        final qty = int.tryParse(qtyVal.toString()) ?? 0;
        counts[id.toString()] = (counts[id.toString()] ?? 0) + qty;
        itemsTotal += qty;
      }
    }

    setState(() {
      revenue = r;
      teaCounts = counts;
      teaNames = teaNames;
      last7 = last7;
      totalOrders = ordersSnap.docs.length;
      totalItemsSold = itemsTotal;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sorted = teaCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Analytics', style: TextStyle(color: Colors.black87)),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Revenue',
                                    style: TextStyle(color: Colors.black54)),
                                const SizedBox(height: 8),
                                Text('\$${revenue.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Orders',
                                      style: TextStyle(color: Colors.black54)),
                                  const SizedBox(height: 8),
                                  Text('$totalOrders',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Items Sold',
                                      style: TextStyle(color: Colors.black54)),
                                  const SizedBox(height: 8),
                                  Text('$totalItemsSold',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 7-day revenue chart
                  const Text('Revenue - Last 7 days',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: last7Labels.map((label) {
                        final val = last7[label] ?? 0.0;
                        final maxVal = last7.values
                            .fold<double>(0.0, (p, e) => e > p ? e : p);
                        final heightFactor = maxVal > 0 ? (val / maxVal) : 0.0;
                        final barHeight = 80.0 * heightFactor + 4.0; // minimum
                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: barHeight,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green[400],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(label, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Top teas (by qty sold)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (sorted.isEmpty)
                    const Text('No sales yet.')
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: sorted.length > 10 ? 10 : sorted.length,
                        itemBuilder: (context, i) {
                          final e = sorted[i];
                          final label = e.key.toString();
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(child: Text('${i + 1}')),
                              title: Text(teaNames[label] ?? label),
                              subtitle: Text('Sold: ${e.value}'),
                            ),
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
