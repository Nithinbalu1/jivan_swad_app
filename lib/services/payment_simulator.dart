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
  /// [rewardsApplied] is the dollar amount covered by rewards (may be 0).
  ///
  /// Returns a [PaymentResult] after a short delay.
  static Future<PaymentResult> processPayment(double amount,
      {String method = 'card', double rewardsApplied = 0.0}) async {
    // If rewards cover the full amount, consider it successful immediately
    final net = (amount - rewardsApplied).clamp(0.0, double.infinity);
    if (net <= 0.0) {
      await Future.delayed(const Duration(milliseconds: 500));
      final txn = 'REWARDS-${DateTime.now().millisecondsSinceEpoch}';
      return PaymentResult(true, txn, 'Paid using rewards');
    }

    // Simulate network latency
    await Future.delayed(const Duration(seconds: 2));

    // Deterministic-ish randomness seeded from time to avoid always same
    final rnd = Random(DateTime.now().millisecondsSinceEpoch);

    // Make success probability dependent on method (cards slightly less likely to fail)
    double failRate = 0.15;
    if (method.toLowerCase().contains('wallet')) failRate = 0.08;
    if (method.toLowerCase().contains('upi')) failRate = 0.12;

    final success = rnd.nextDouble() > failRate;

    if (success) {
      final txn = 'SIM-${DateTime.now().millisecondsSinceEpoch}';
      return PaymentResult(true, txn, 'Payment successful (simulated)');
    }

    return PaymentResult(false, '', 'Payment declined by simulator');
  }
}
