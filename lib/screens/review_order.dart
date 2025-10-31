import 'package:flutter/material.dart';
import '../services/payment_simulator.dart';
import 'payment_method.dart';

class OrderItem {
  final String name;
  final int priceCents;
  final int qty;

  const OrderItem({
    required this.name,
    required this.priceCents,
    this.qty = 1,
  });

  int get lineTotalCents => priceCents * qty;
}

class ReviewOrderArgs {
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final int rewardsPoints;
  final List<OrderItem> items;

  final String? initialPaymentLabel;

  const ReviewOrderArgs({
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.rewardsPoints,
    required this.items,
    this.initialPaymentLabel,
  });

  int get subtotalCents => items.fold(0, (sum, it) => sum + it.lineTotalCents);
}

/// ---------------- Screen ----------------

class ReviewOrderScreen extends StatefulWidget {
  final ReviewOrderArgs args;
  const ReviewOrderScreen({super.key, required this.args});

  @override
  State<ReviewOrderScreen> createState() => _ReviewOrderScreenState();
}

class _ReviewOrderScreenState extends State<ReviewOrderScreen> {
  static const double _njTaxRate = 0.06625; // NJ 6.625%

  // Use the static PaymentSimulator.processPayment(dollars) for simulated
  // payment processing.
  String? _paymentLabel;
  Map<String, String>? _billingSelected;

  bool _applyRewards = false;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _paymentLabel = widget.args.initialPaymentLabel;
  }

  int _earnedPoints(int subtotalCents) =>
      (subtotalCents / 100).floor(); // 1 pt per $ spent
  int _redeemableCentsFromPoints(int points) =>
      (points ~/ 100) * 100; // Redeem 100 pts = $1.00

  String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

  Future<void> _pickPaymentMethod() async {
    final res = await Navigator.push<Map<String, Object?>>(
      context,
      MaterialPageRoute(builder: (_) => const PaymentMethodScreen()),
    );
    if (res == null) return;

    final payment = Map<String, String>.from(res['payment'] as Map);
    final billing = Map<String, String>.from((res['billing'] as Map?) ?? {});
    setState(() {
      _paymentLabel = payment['masked']; // "Visa •••• 4242"
      _billingSelected = billing;
    });
  }

  Future<void> _placeOrder(int totalCents) async {
    setState(() => _placing = true);
    try {
      // Our simulator uses dollars; convert cents -> dollars
      final amountDollars = totalCents / 100.0;
      final res = await PaymentSimulator.processPayment(amountDollars);

      if (!mounted) return;

      final msg = res.success
          ? 'Authorized • TXN ${res.transactionId}'
          : 'Declined • ${res.message}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

      if (res.success) {
        // Optionally navigate to success screen
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    final subtotal = args.subtotalCents;
    final earnedPts = _earnedPoints(subtotal);
    final availablePts = args.rewardsPoints;
    final redeemableCents = _redeemableCentsFromPoints(availablePts);

    final appliedRewardCents =
        _applyRewards ? redeemableCents.clamp(0, subtotal) : 0;

    final discountedSubtotal = subtotal - appliedRewardCents;
    final taxCents = (discountedSubtotal * _njTaxRate).round();

    final total = discountedSubtotal + taxCents;

    final canPlace = subtotal > 0 && _paymentLabel != null && !_placing;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Review order'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ---- Customer Info ----
          _Section(
            title: 'Customer Info',
            child: Column(
              children: [
                _kv('Name', args.customerName),
                _kv('Email', args.customerEmail),
                _kv('Phone', args.customerPhone),
              ],
            ),
          ),

          // ---- Rewards ----
          _Section(
            title: 'Rewards points',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _kv('Available',
                    '${availablePts} pts (${_money(redeemableCents)})'),
                _kv('Earn on this order', '$earnedPts pts'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Use rewards points',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Switch.adaptive(
                      value: _applyRewards,
                      activeColor: Colors.blue, // iOS-style blue toggle
                      onChanged: (v) => setState(() => _applyRewards = v),
                    ),
                  ],
                ),
                if (_applyRewards && appliedRewardCents > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Applied: -${_money(appliedRewardCents)}',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                    ),
                  ),
              ],
            ),
          ),

          // ---- Payment Method ----
          _Section(
            title: 'Payment method',
            trailing: const Icon(Icons.chevron_right),
            subtitle: (_paymentLabel == null)
                ? Row(children: const [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                    SizedBox(width: 6),
                    Text('Payment is required',
                        style: TextStyle(color: Colors.orange)),
                  ])
                : null,
            onTap: _pickPaymentMethod,
            child: Text(_paymentLabel ?? 'Tap to add a method'),
          ),

          // ---- Order Summary ----
          _Section(
            title: 'Order summary',
            child: Column(
              children: [
                _kv('Subtotal', _money(subtotal)),
                if (_applyRewards && appliedRewardCents > 0)
                  _kv('Rewards applied', '-${_money(appliedRewardCents)}',
                      bold: false),
                _kv('Tax (NJ 6.625%)', _money(taxCents)),
                const SizedBox(height: 8),
                _kv('Total', _money(total), bold: true),
              ],
            ),
          ),

          const SizedBox(height: 84),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: canPlace ? () => _placeOrder(total) : null,
            child: _placing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Place order'),
          ),
        ),
      ),
    );
  }
}

/// ---------------- UI helpers ----------------

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final Widget? subtitle;
  final VoidCallback? onTap;

  const _Section({
    required this.title,
    required this.child,
    this.trailing,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE9E9E9))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700))),
              if (trailing != null) trailing!,
            ]),
            if (subtitle != null)
              Padding(padding: const EdgeInsets.only(top: 4), child: subtitle!),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

Widget _kv(String k, String v, {bool bold = false}) {
  final style = TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: style),
        Flexible(child: Text(v, style: style, textAlign: TextAlign.right)),
      ],
    ),
  );
}
