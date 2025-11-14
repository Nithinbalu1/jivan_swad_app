// lib/provider/provider_home.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';
import 'manage_teas.dart';
import 'manage_orders.dart';
import 'analytics.dart';

class ProviderHome extends StatefulWidget {
  const ProviderHome({super.key});

  @override
  State<ProviderHome> createState() => _ProviderHomeState();
}

class _ProviderHomeState extends State<ProviderHome> {
  final _teasRef = FirebaseFirestore.instance.collection('teas');
  final _ordersRef = FirebaseFirestore.instance.collection('orders');

  Future<int> _countTeas() async {
    final s = await _teasRef.get();
    return s.size;
  }

  Future<int> _countOrders() async {
    final s = await _ordersRef.get();
    return s.size;
  }

  Future<double> _computeRevenue() async {
    final s = await _ordersRef.get();
    double total = 0.0;
    for (final d in s.docs) {
      final t = d['total'];
      if (t is num) total += t.toDouble();
      if (t is String) total += double.tryParse(t) ?? 0.0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4DB5BD);
    final size = MediaQuery.of(context).size;
    final cross = size.width > 700 ? 3 : 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Provider Dashboard',
                style: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.bold)),
            SizedBox(height: 2),
            Text('Manage your shop & orders',
                style: TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero banner like customer home
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.08), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manage your shop',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ManageOrdersScreen()),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Manage Orders',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ManageTeasScreen()),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Manage Teas',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Summary cards
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                              child: _FutureStat(
                                  label: 'Teas', future: _countTeas())),
                          Expanded(
                              child: _FutureStat(
                                  label: 'Orders', future: _countOrders())),
                          Expanded(
                              child: _FutureStatDouble(
                                  label: 'Revenue', future: _computeRevenue())),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Action grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: cross,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _ActionTile(
                        icon: Icons.emoji_food_beverage,
                        label: 'Manage Teas',
                        color: Colors.brown,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ManageTeasScreen())),
                      ),
                      _ActionTile(
                        icon: Icons.receipt_long,
                        label: 'Manage Orders',
                        color: Colors.indigo,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ManageOrdersScreen())),
                      ),
                      _ActionTile(
                        icon: Icons.show_chart,
                        label: 'Analytics',
                        color: Colors.teal,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AnalyticsScreen())),
                      ),
                      _ActionTile(
                        icon: Icons.settings,
                        label: 'Settings',
                        color: Colors.grey,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Settings coming soon'))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book), label: 'Catalog'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
        onTap: (i) async {
          if (i == 1) {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ManageTeasScreen()));
          } else if (i == 2) {
            // show account logout
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Account'),
                content: const Text('Log out of provider account?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                    onPressed: () async {
                      await AuthService.logout();
                      if (!mounted) return;
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AuthScreen()));
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ManageTeasScreen())),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FutureStat extends StatelessWidget {
  final String label;
  final Future<int> future;
  const _FutureStat({required this.label, required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snap) {
        final value = snap.hasData ? snap.data.toString() : '—';
        return Column(
          children: [
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      },
    );
  }
}

class _FutureStatDouble extends StatelessWidget {
  final String label;
  final Future<double> future;
  const _FutureStatDouble({required this.label, required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: future,
      builder: (context, snap) {
        final value = snap.hasData ? '\$${snap.data!.toStringAsFixed(2)}' : '—';
        return Column(
          children: [
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color)),
            const SizedBox(height: 12),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
