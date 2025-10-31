// lib/services/payment_stimulator.dart
import 'dart:math';

enum PaymentOutcome { authorized, error }

class PaymentDisplay {
  final PaymentOutcome outcome;
  final String message;
  final int amount;          // cents
  final String? authCode;    // when authorized
  final String? receiptNumber;

  const PaymentDisplay({
    required this.outcome,
    required this.message,
    required this.amount,
    this.authCode,
    this.receiptNumber,
  });
}

class PaymentStimulator {
  // NJ sales tax 6.625%
  static const double _njTaxRate = 0.06625;

  int _attempts = 0;
  int get attempt => _attempts;
  static double get taxRate => _njTaxRate;

  int taxOn(int subtotalCents) => (subtotalCents * taxRate).round();
  int totalFromSubtotal(int subtotalCents) => subtotalCents + taxOn(subtotalCents);

  // ---------- validators ----------
  String? _validateName(String raw) {
    final ok = RegExp(r'^[A-Za-z ]{2,}$').hasMatch(raw.trim());
    return ok ? null : 'Card name must contain letters and spaces only.';
  }

  String? _validateCardNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 16) return 'Card number must be 16 digits.';
    return null;
  }

  String? _validateExpiry(String raw) {
    final m = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2})$').firstMatch(raw.trim());
    if (m == null) return 'Expiry must be in MM/YY format.';
    final mm = int.parse(m.group(1)!);
    final yy = int.parse(m.group(2)!);
    final yr = 2000 + yy;

    // Allowed window 2025–2030 and not past month
    if (yr < 2025 || yr > 2030) return 'Card expired or unsupported year (2025–2030).';
    final lastMoment = DateTime(yr, mm + 1, 0, 23, 59, 59);
    if (lastMoment.isBefore(DateTime.now())) return 'Card expired.';
    return null;
  }

  String? _validateCVV(String raw) {
    final ok = RegExp(r'^\d{3,4}$').hasMatch(raw.trim());
    return ok ? null : 'CVV must be 3–4 digits.';
  }

  /// Billing address constraints:
  /// fullName letters/spaces; street required;
  /// zip 5 digits; state 2 letters; city letters/spaces; phone 10–15 digits.
  String? _validateBilling(Map<String, String> b) {
    String err(String m) => 'Billing: $m';

    final fullName = b['fullName'] ?? '';
    if (!RegExp(r'^[A-Za-z ]{2,}$').hasMatch(fullName.trim())) {
      return err('Full name must contain letters and spaces only.');
    }

    final street = b['street'] ?? '';
    if (street.trim().isEmpty) return err('Street address is required.');

    final zip = b['zip'] ?? '';
    if (!RegExp(r'^\d{5}$').hasMatch(zip)) return err('Zip code must be 5 digits.');

    final state = b['state'] ?? '';
    if (!RegExp(r'^[A-Za-z]{2}$').hasMatch(state)) return err('State must be 2 letters.');

    final city = b['city'] ?? '';
    if (!RegExp(r'^[A-Za-z ]{2,}$').hasMatch(city.trim())) {
      return err('City must contain letters and spaces only.');
    }

    final phone = b['phone'] ?? '';
    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length < 10 || phoneDigits.length > 15) {
      return err('Phone must contain 10–15 digits.');
    }
    return null;
  }

  // ---------- "charge" ----------
  Future<PaymentDisplay> charge({
    required int subtotalCents,
    required String cardNumber,
    required String nameOnCard,
    required String expMMYY,
    required String cvv,
    required Map<String, String> billing,
  }) async {
    _attempts++;

    final validations = <String?>[
      _validateCardNumber(cardNumber),
      _validateName(nameOnCard),
      _validateExpiry(expMMYY),
      _validateCVV(cvv),
      _validateBilling(billing),
    ];

    final firstError = validations.firstWhere((e) => e != null, orElse: () => null);
    if (firstError != null) {
      return PaymentDisplay(
        outcome: PaymentOutcome.error,
        message: 'Card declined: $firstError',
        amount: totalFromSubtotal(subtotalCents),
      );
    }

    final total = totalFromSubtotal(subtotalCents);
    final auth = 'AUTH${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(90) + 10}';
    final rcpt = 'RCPT${DateTime.now().millisecondsSinceEpoch}';

    return PaymentDisplay(
      outcome: PaymentOutcome.authorized,
      message: 'Payment Confirmed. Thank you for your purchase!',
      amount: total,
      authCode: auth,
      receiptNumber: rcpt,
    );
  }
}

  
  
