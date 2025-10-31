import '../models/payment_display.dart';

//Payment Stimulator
class PaymentStimulator {
  int _attempts = 0; //Starts at 0
  int get attempt => _attempts;
  static const double taxRate = 0.06625;
  double calculateTotal(double subtotal) {
    return subtotal + (subtotal * taxRate);
  }

PaymentDisplay authorize({ 
  required double subtotal, //the $ amount 00.00
  required String cardName,
  required String last4, //the last 4 digits of the card
}) {
  
PaymentDisplay processPayment 
  _attempts++; //payment attempts increase by 1
  final total = calculateTotal(double subtotal);
  final subtotalValid = subtotal > 0;

  static const paymentError = 'Payment Error. We are unable to process your payment. Please try again.'
  static const paymentConfirmed = 'Payment Confirmed. Thank you for your purchase!'
    

  if (subtotalValid && nameValid && last4Valid) {
    return PaymentDisplay (
      outcome: PaymentOutcome 

  if (!(subtotalValid && nameValid && last4Valid)) {
      return PaymentDisplay(
        outcome: PaymentOutcome.error,
        message: paymentError,
        amount: total,
      );
    }

    final receipt = 'RCPT${DateTime.now().millisecondsSinceEpoch}';
    return PaymentDisplay(
      outcome: PaymentOutcome.confirmed,
      message: paymentSuccess,
      amount: total,
      receiptNumber: receipt,
      payerName: name,
      last4: l4,
    );
  }
}

  
  
  
  
