import '../lib/services/payment_simulator.dart';

Future<void> main() async {
  print('Testing PaymentSimulator...');
  final res = await PaymentSimulator.processPayment(5.0, method: 'card');
  print(
      'Result: success=${res.success}, txn=${res.transactionId}, msg=${res.message}');
}
