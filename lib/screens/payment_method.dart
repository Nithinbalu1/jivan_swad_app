// lib/screens/payment_method.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formatter for phone number: XXX-XXX-XXXX (dashes at 3 and 6)
/// and hard-limit to 10 digits.
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      digits = digits.substring(0, 10); // hard stop at 10 digits
    }

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write('-');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatter for expiry date: MM/YY (slash auto after 2 digits)
class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) {
      digits = digits.substring(0, 4); // max 4 digits
    }

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

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

  // ---- validators ----
  String? _lettersOnly(String? v, {String field = 'This field'}) {
    final s = (v ?? '').trim();
    if (!RegExp(r'^[A-Za-z ]{2,}$').hasMatch(s)) {
      return '$field must contain letters and spaces only';
    }
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
    if (!RegExp(r'^\d{3,4}$').hasMatch((v ?? '').trim())) {
      return '3–4 digits';
    }
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
    if (d.length != 10) {
      return 'Phone must be 10 digits';
    }
    return null;
  }

  void _saveAndClose() {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;

    final label = _methodLabel(_selectedMethod);

    // Pop back to the review screen with the label (String)
    Navigator.pop<String>(context, label);
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
                    onSelected: (_) =>
                        setState(() => _selectedMethod = 'card'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('UPI'),
                    selected: _selectedMethod == 'upi',
                    onSelected: (_) =>
                        setState(() => _selectedMethod = 'upi'),
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
                decoration: const InputDecoration(
                  labelText: 'Card number',
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 16,
                validator: _card16,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: expCtrl,
                      decoration: const InputDecoration(
                        labelText: 'MM/YY',
                        counterText: '',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        ExpiryDateFormatter(),
                      ],
                      maxLength: 5,
                      validator: _exp,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: cvvCtrl,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        counterText: '',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      maxLength: 4,
                      validator: _cvv,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name on card'),
                validator: (v) => _selectedMethod == 'card'
                    ? _lettersOnly(v, field: 'Name on card')
                    : null,
              ),
            ],

            if (_selectedMethod != 'card') ...[
              TextFormField(
                decoration: const InputDecoration(labelText: 'UPI / Wallet ID'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 20),
            const Text(
              'Billing address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: zipCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Zip code',
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    maxLength: 5,
                    validator: _zip,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: stateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      counterText: '',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 2,
                    validator: _state2,
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: cityCtrl,
              decoration: const InputDecoration(labelText: 'City'),
              validator: (v) => _lettersOnly(v, field: 'City'),
            ),
            TextFormField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: 'XXX-XXX-XXXX',
              ),
              keyboardType: TextInputType.phone,
              validator: _phone,
              inputFormatters: [
                PhoneNumberFormatter(),
              ],
              maxLength: 12, // XXX-XXX-XXXX
              buildCounter: (
                _, {
                required int currentLength,
                required bool isFocused,
                required int? maxLength,
              }) =>
                  const SizedBox.shrink(),
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

