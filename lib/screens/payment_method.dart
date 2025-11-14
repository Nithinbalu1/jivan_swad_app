// lib/screens/payment_method.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final _form = GlobalKey<FormState>();

  // Card
  final cardCtrl = TextEditingController();
  final expCtrl = TextEditingController(); // MM/YY
  final cvvCtrl = TextEditingController();
  final nameCtrl = TextEditingController();

  // Billing
  final fullNameCtrl = TextEditingController();
  final streetCtrl = TextEditingController();
  final aptCtrl = TextEditingController();
  final zipCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  String _selectedMethod = 'card';

  @override
  void dispose() {
    for (final c in [
      cardCtrl,
      expCtrl,
      cvvCtrl,
      nameCtrl,
      fullNameCtrl,
      streetCtrl,
      aptCtrl,
      zipCtrl,
      stateCtrl,
      cityCtrl,
      phoneCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _maskedFromCard(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return 'Add a card';
    final last4 = d.length <= 4 ? d : d.substring(d.length - 4);
    return 'Card •••• $last4';
  }

  String _methodLabel(String type) {
    switch (type) {
      case 'card':
        return _maskedFromCard(cardCtrl.text);
      case 'upi':
        return 'UPI';
      case 'wallet':
        return 'Wallet';
      default:
        return 'Payment';
    }
  }

  // ---- validators (mirror simulator rules for UX) ----
  String? _lettersOnly(String? v, {String field = 'This field'}) {
    final s = (v ?? '').trim();
    if (!RegExp(r'^[A-Za-z ]{2,}$').hasMatch(s))
      return '$field must contain letters and spaces only';
    return null;
  }

  String? _card16(String? v) {
    final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.length != 16) return 'Card number must be 16 digits';
    return null;
  }

  String? _exp(String? v) {
    final s = (v ?? '').trim();
    final m = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2})$').firstMatch(s);
    if (m == null) return 'Use MM/YY';
    final mm = int.parse(m.group(1)!);
    final yy = int.parse(m.group(2)!);
    final yr = 2000 + yy;
    if (yr < 2025 || yr > 2030) return 'Year 2025–2030 only';
    final lastMoment = DateTime(yr, mm + 1, 0, 23, 59, 59);
    if (lastMoment.isBefore(DateTime.now())) return 'Card expired';
    return null;
  }

  String? _cvv(String? v) {
    if (!RegExp(r'^\d{3,4}$').hasMatch((v ?? '').trim())) return '3–4 digits';
    return null;
  }

  String? _required(String? v, {String field = 'This field'}) =>
      ((v ?? '').trim().isEmpty) ? '$field is required' : null;

  String? _zip(String? v) =>
      RegExp(r'^\d{5}$').hasMatch((v ?? '')) ? null : 'Zip must be 5 digits';

  String? _state2(String? v) =>
      RegExp(r'^[A-Za-z]{2}$').hasMatch((v ?? '')) ? null : 'State = 2 letters';

  String? _phone(String? v) {
    final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.length < 10 || d.length > 15) return 'Phone must be 10–15 digits';
    return null;
  }

  void _saveAndClose() {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;

    final billing = <String, String>{
      'fullName': fullNameCtrl.text.trim(),
      'street': streetCtrl.text.trim(),
      'apt': aptCtrl.text.trim(),
      'zip': zipCtrl.text.trim(),
      'state': stateCtrl.text.trim().toUpperCase(),
      'city': cityCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
    };

    Navigator.pop<Map<String, Object?>>(context, {
      'payment': {
        'masked': _methodLabel(_selectedMethod),
        'type': _selectedMethod,
        'card': cardCtrl.text,
        'exp': expCtrl.text,
        'cvv': cvvCtrl.text,
        'name': nameCtrl.text,
      },
      'billing': billing,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment method')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Method selection
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Card'),
                    selected: _selectedMethod == 'card',
                    onSelected: (_) => setState(() => _selectedMethod = 'card'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('UPI'),
                    selected: _selectedMethod == 'upi',
                    onSelected: (_) => setState(() => _selectedMethod = 'upi'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Wallet'),
                    selected: _selectedMethod == 'wallet',
                    onSelected: (_) =>
                        setState(() => _selectedMethod = 'wallet'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Card fields shown only when selected
            if (_selectedMethod == 'card') ...[
              TextFormField(
                controller: cardCtrl,
                decoration: const InputDecoration(labelText: 'Card number'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 16,
                validator: _card16,
              ),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: expCtrl,
                    decoration: const InputDecoration(labelText: 'MM/YY'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
                    ],
                    validator: _exp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: cvvCtrl,
                    decoration: const InputDecoration(labelText: 'CVV'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 4,
                    validator: _cvv,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name on card'),
                validator: (v) => _selectedMethod == 'card'
                    ? _lettersOnly(v, field: 'Name on card')
                    : null,
              ),
            ], // End card fields

            if (_selectedMethod != 'card') ...[
              // For non-card methods, collect a short identifier (UPI id or wallet id)
              TextFormField(
                decoration: const InputDecoration(labelText: 'UPI / Wallet ID'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 20),
            const Text('Billing address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextFormField(
              controller: fullNameCtrl,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => _lettersOnly(v, field: 'Full name'),
            ),
            TextFormField(
              controller: streetCtrl,
              decoration: const InputDecoration(labelText: 'Street address'),
              validator: (v) => _required(v, field: 'Street address'),
            ),
            TextFormField(
              controller: aptCtrl,
              decoration:
                  const InputDecoration(labelText: 'Apt/suite (optional)'),
            ),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: zipCtrl,
                  decoration: const InputDecoration(labelText: 'Zip code'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 5,
                  validator: _zip,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: stateCtrl,
                  decoration: const InputDecoration(labelText: 'State'),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 2,
                  validator: _state2,
                ),
              ),
            ]),
            TextFormField(
              controller: cityCtrl,
              decoration: const InputDecoration(labelText: 'City'),
              validator: (v) => _lettersOnly(v, field: 'City'),
            ),
            TextFormField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone number'),
              keyboardType: TextInputType.phone,
              validator: _phone,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saveAndClose,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
