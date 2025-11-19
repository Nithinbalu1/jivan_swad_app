import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_state.dart';

/// Location selection screen
class LocationScreen extends StatefulWidget {
  final String? currentLocation;

  const LocationScreen({super.key, this.currentLocation});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController _addrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addrController.text = AppState.instance.deliveryAddress.value ?? '';
  }

  @override
  void dispose() {
    _addrController.dispose();
    super.dispose();
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
          'From your favorite\nlocation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            height: 1.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Colors.black54),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Find your closest location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Service type selector (Pickup / Delivery)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'pickup',
                            groupValue: AppState.instance.serviceType.value,
                            onChanged: (v) {
                              AppState.instance.setServiceType('pickup');
                              setState(() {});
                            },
                          ),
                          const Text('Pickup at store'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'delivery',
                            groupValue: AppState.instance.serviceType.value,
                            onChanged: (v) {
                              AppState.instance.setServiceType('delivery');
                              setState(() {});
                            },
                          ),
                          const Text('Deliver to me'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Delivery address input shown when delivery selected
              if (AppState.instance.serviceType.value == 'delivery') ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _addrController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter your delivery address',
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Reset to saved address
                          _addrController.text =
                              AppState.instance.deliveryAddress.value ?? '';
                          setState(() {});
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final addr = _addrController.text.trim();
                          if (addr.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please enter an address')));
                            return;
                          }
                          AppState.instance.setDeliveryAddress(addr);
                          AppState.instance.setServiceType('delivery');
                          AppState.instance.setLocation('Delivery: $addr');
                          Navigator.pop(context, 'Delivery: $addr');
                        },
                        child: const Text('Save & Use'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Locations list (backed by Firestore `stores` collection so updates by admin appear live)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stores')
                    .orderBy('name')
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('Failed to load stores: ${snap.error}'),
                    );
                  }
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No stores available'),
                    );
                  }

                  return Column(
                    children: docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? d.id) as String;
                      final phone = (data['phone'] ?? '') as String;
                      final address = (data['address'] ?? '') as String;
                      final status = (data['status'] ?? 'Closed now') as String;
                      final supportsPickup =
                          (data['supportsPickup'] ?? true) as bool;
                      final isSelected = name == widget.currentLocation;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color:
                                isSelected ? primaryColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (isSelected)
                                        Icon(Icons.check_circle,
                                            color: primaryColor),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (phone.isNotEmpty)
                                Text(
                                  phone,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              if (address.isNotEmpty)
                                Text(
                                  address,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    status,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.expand_more, size: 16),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (supportsPickup)
                                Row(
                                  children: const [
                                    Icon(Icons.store, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Pickup',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // When user chooses a store, set service type to pickup and set location
                                    AppState.instance.setServiceType('pickup');
                                    AppState.instance.setLocation(name);
                                    Navigator.pop(context, name);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Order',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
