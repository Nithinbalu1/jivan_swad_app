import 'package:flutter/material.dart';
import 'billing_address.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final cardCtrl = TextEditingController();
  final expCtrl  = TextEditingController();
  final cvvCtrl  = TextEditingController();
  final nameCtrl = TextEditingController();

  Map<String, String>? _billing;

  @override
  void dispose() {
    cardCtrl.dispose();
    expCtrl.dispose();
    cvvCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _editBilling() async {
    final res = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => BillingAddressScreen(initial: _billing)),
    );
    if (res != null) setState(() => _billing = res);
  }

  String _maskedFromCard(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Add a card';
    final last4 = digits.length <= 4 ? digits : digits.substring(digits.length - 4);
    return 'Card •••• $last4';
  }

  void _saveAndClose() {
    Navigator.pop<Map<String, Object?>>(
      context,
      {
        'payment': {'masked': _maskedFromCard(cardCtrl.text)},
        'billing': _billing ?? <String, String>{},
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingSubtitle =
        (_billing == null || (_billing!['street'] ?? '').isEmpty)
            ? 'Add billing address'
            : '${_billing!['fullName'] ?? ''}\n'
              '${_billing!['street'] ?? ''}${(_billing!['apt'] ?? '').isEmpty ? '' : ' ${_billing!['apt']}'}\n'
              '${_billing!['city'] ?? ''}, ${_billing!['state'] ?? ''} ${_billing!['zip'] ?? ''}';

    return Scaffold(
      appBar: AppBar(title: const Text('Add a credit or debit card')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(decoration: const InputDecoration(labelText: 'Card number'), controller: cardCtrl, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(decoration: const InputDecoration(labelText: 'MM/YY'), controller: expCtrl, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: TextField(decoration: const InputDecoration(labelText: 'CVV'), controller: cvvCtrl, keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(labelText: 'Name on card'), controller: nameCtrl),
          const SizedBox(height: 20),

          const Text('Billing address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(billingSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editBilling,
          ),

          const SizedBox(height: 24),
          SizedBox(height: 48, child: ElevatedButton(onPressed: _saveAndClose, child: const Text('Save'))),
        ],
      ),
    );
  }
}

