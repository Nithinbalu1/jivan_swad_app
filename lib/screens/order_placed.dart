import 'package:flutter/material.dart';

class PickupLocationScreen extends StatefulWidget {
  const PickupLocationScreen({super.key});

  @override
  State<PickupLocationScreen> createState() => _PickupLocationScreenState();
}

class _PickupLocationScreenState extends State<PickupLocationScreen> {
  final TextEditingController phoneController = TextEditingController();

  // Example store location (fixed, not editable)
  final String storeAddress = "123 Main St, Hackensack, NJ 07601";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pickup Info")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pickup Person", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone Number"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            const Text("Pickup Location", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(storeAddress),
            const Spacer(),

            ElevatedButton(
              onPressed: () {
                // Save phone and move to review order
                Navigator.pushNamed(
                  context,
                  "/reviewOrder",
                  arguments: phoneController.text.trim(),
                );
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
