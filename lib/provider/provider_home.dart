// lib/provider/provider_home.dart
import 'package:flutter/material.dart';
import 'manage_teas.dart';
import 'manage_orders.dart';
import 'analytics.dart';

class ProviderHome extends StatelessWidget {
  const ProviderHome({super.key});

  @override
  Widget build(BuildContext context) {
    final cardStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            // Top stats row (placeholder, replace with real data)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _StatTile(label: 'Teas', value: '12'),
                    _StatTile(label: 'Orders', value: '24'),
                    _StatTile(label: 'Revenue', value: '\$1.2k'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Navigation grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    style: cardStyle,
                    icon: const Icon(Icons.local_cafe, size: 28),
                    label: const Text('Manage Teas', textAlign: TextAlign.center),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageTeasScreen()),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: cardStyle,
                    icon: const Icon(Icons.receipt_long, size: 28),
                    label: const Text('Manage Orders', textAlign: TextAlign.center),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageOrdersScreen()),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: cardStyle,
                    icon: const Icon(Icons.show_chart, size: 28),
                    label: const Text('Analytics', textAlign: TextAlign.center),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: cardStyle,
                    icon: const Icon(Icons.settings, size: 28),
                    label: const Text('Settings', textAlign: TextAlign.center),
                    onPressed: () {
                      // placeholder for future
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings coming soon')));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
