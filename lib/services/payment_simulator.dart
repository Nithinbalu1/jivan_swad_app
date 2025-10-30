import 'dart:async';
import 'dart:math';

/// Simple payment result model for the simulator.
class PaymentResult {
  final bool success;
  final String transactionId;
  final String message;

  PaymentResult(this.success, this.transactionId, this.message);
}

/// A tiny payment simulator that mimics network latency and random
/// success/failure. Useful for local/dev testing when no real gateway
/// is available.
class PaymentSimulator {
  /// Simulate a payment of [amount]. [method] is a free-form string
  /// representing the payment method (e.g., 'card', 'upi', 'wallet').
  ///
  /// Returns a [PaymentResult] after a short delay.
  static Future<PaymentResult> processPayment(double amount,
      {String method = 'card'}) async {
    // Simulate network latency
    await Future.delayed(const Duration(seconds: 2));

    // Deterministic-ish randomness seeded from time to avoid always same
    final rnd = Random(DateTime.now().millisecondsSinceEpoch);
    // Fail ~15% of the time to simulate declined payments
    final success = rnd.nextDouble() > 0.15;

    if (success) {
      final txn = 'SIM-${DateTime.now().millisecondsSinceEpoch}';
      return PaymentResult(true, txn, 'Payment successful (simulated)');
    }

    return PaymentResult(false, '', 'Payment declined by simulator');
  }
}
