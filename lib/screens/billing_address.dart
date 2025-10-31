import 'package:flutter/material.dart';

/// Minimal billing address editor used by the payment flow.
/// Returns a Map<String,String> with common keys when the user saves.
class BillingAddressScreen extends StatefulWidget {
  final Map<String, String>? initial;
  const BillingAddressScreen({super.key, this.initial});

  @override
  State<BillingAddressScreen> createState() => _BillingAddressScreenState();
}

class _BillingAddressScreenState extends State<BillingAddressScreen> {
  late final TextEditingController _fullName;
  late final TextEditingController _street;
  late final TextEditingController _apt;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _zip;

  @override
  void initState() {
    super.initState();
    final init = widget.initial ?? <String, String>{};
    _fullName = TextEditingController(text: init['fullName'] ?? '');
    _street = TextEditingController(text: init['street'] ?? '');
    _apt = TextEditingController(text: init['apt'] ?? '');
    _city = TextEditingController(text: init['city'] ?? '');
    _state = TextEditingController(text: init['state'] ?? '');
    _zip = TextEditingController(text: init['zip'] ?? '');
  }

  @override
  void dispose() {
    _fullName.dispose();
    _street.dispose();
    _apt.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop<Map<String, String>>(context, {
      'fullName': _fullName.text,
      'street': _street.text,
      'apt': _apt.text,
      'city': _city.text,
      'state': _state.text,
      'zip': _zip.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing address')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
              controller: _fullName,
              decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 8),
          TextField(
              controller: _street,
              decoration: const InputDecoration(labelText: 'Street')),
          const SizedBox(height: 8),
          TextField(
              controller: _apt,
              decoration:
                  const InputDecoration(labelText: 'Apt / Suite (optional)')),
          const SizedBox(height: 8),
          TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City')),
          const SizedBox(height: 8),
          TextField(
              controller: _state,
              decoration: const InputDecoration(labelText: 'State')),
          const SizedBox(height: 8),
          TextField(
              controller: _zip,
              decoration: const InputDecoration(labelText: 'ZIP')),
          const SizedBox(height: 20),
          SizedBox(
              height: 48,
              child:
                  ElevatedButton(onPressed: _save, child: const Text('Save'))),
        ],
      ),
    );
  }
}
