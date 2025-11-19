// lib/screens/review_order.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/payment_simulator.dart';
import 'payment_method.dart';

/// ---- Simple cart model ----
class OrderItem {
  final String name;
  final int priceCents;
  final int qty;
  const OrderItem({required this.name, required this.priceCents, this.qty = 1});
  int get lineTotalCents => priceCents * qty;
}

/// Arguments you pass when opening this screen
class ReviewOrderArgs {
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final List<OrderItem> items;

  /// Rewards balance in points (100 pts == $1.00). Default 0.
  final int rewardsPoints;

  /// Optional prefilled label like "Card •••• 4242"
  final String? initialPaymentLabel;

  const ReviewOrderArgs({
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.items,
    this.rewardsPoints = 0,
    this.initialPaymentLabel,
  });

  int get subtotalCents => items.fold(0, (sum, it) => sum + it.lineTotalCents);
}

/// ---- Screen ----
class ReviewOrderScreen extends StatefulWidget {
  final ReviewOrderArgs args;
  const ReviewOrderScreen({super.key, required this.args});

  @override
  State<ReviewOrderScreen> createState() => _ReviewOrderScreenState();
}

class _ReviewOrderScreenState extends State<ReviewOrderScreen> {
  static const double _njTaxRate = 0.06625; // NJ 6.625%

  String? _paymentLabel;
  String? _paymentType;
  // payment related details are stored transiently in the payment screen and
  // we only keep the human-visible payment label here.

  bool _placing = false;

  // Rewards redemption state (points = cents equivalent; 100 pts == $1)
  bool _useRewards = false;
  int _appliedPoints = 0;

  String _money(int cents) {
    final fmt = NumberFormat.simpleCurrency(locale: 'en_US');
    return fmt.format(cents / 100);
  }

  @override
  void initState() {
    super.initState();
    _paymentLabel = widget.args.initialPaymentLabel;
  }

  Future<void> _pickPaymentMethod() async {
    final res = await Navigator.push<Map<String, Object?>>(
      context,
      MaterialPageRoute(builder: (_) => const PaymentMethodScreen()),
    );
    if (res == null) return;

    final payment = (res['payment'] as Map?)?.cast<String, String>();

    if (!mounted) return;
    setState(() {
      _paymentLabel = payment?['masked'];
      _paymentType = payment?['type'];
    });
  }

  Widget _paymentIcon(String? type) {
    if (type == null) return const SizedBox.shrink();
    final t = type.toLowerCase();
    if (t.contains('card')) return const Icon(Icons.credit_card, size: 20);
    if (t.contains('upi'))
      return const Icon(Icons.account_balance_wallet, size: 20);
    if (t.contains('wallet'))
      return const Icon(Icons.account_balance_wallet, size: 20);
    if (t.contains('paypal')) return const Icon(Icons.payment, size: 20);
    return const Icon(Icons.payment, size: 20);
  }

  Future<void> _placeOrder() async {
    if (_placing) return;
    setState(() => _placing = true);
    try {
      final subtotal = widget.args.subtotalCents;
      final taxCents = (subtotal * _njTaxRate).round();
      final total = subtotal + taxCents;
      final netCents = (total - _appliedPoints).clamp(0, 1 << 30);

      final amountDollars = netCents / 100.0;

      final res = await PaymentSimulator.processPayment(amountDollars,
          method: _paymentType ?? 'card',
          rewardsApplied: _appliedPoints / 100.0);

      if (!mounted) return;

      if (res.success) {
        // Show a success dialog with transaction id and an action
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Payment successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transaction: ${res.transactionId}'),
                const SizedBox(height: 8),
                Text('Amount: ${_money(netCents)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );

        // After the dialog closes, return success to caller so they can create
        // the order in Firestore and navigate to order history.
        if (mounted) Navigator.of(context).pop(true);
      } else {
        // Show an error dialog with retry option
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Payment failed'),
            content: Text(res.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _placeOrder(); // retry
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    final subtotal = args.subtotalCents;
    final taxCents = (subtotal * _njTaxRate).round();
    final total = subtotal + taxCents;

    // Cap applied points to available and not more than total
    final maxRedeemable =
        args.rewardsPoints < total ? args.rewardsPoints : total;
    if (!_useRewards) _appliedPoints = 0;
    if (_appliedPoints > maxRedeemable) _appliedPoints = maxRedeemable;

    final totalAfterRewards = (total - _appliedPoints).clamp(0, 1 << 30);

    final canPlace = subtotal > 0 &&
        !_placing &&
        (_paymentLabel != null || totalAfterRewards == 0);

    final rewardsLabel =
        '${_money(args.rewardsPoints)} (${args.rewardsPoints} points) available';

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
          _Section(
            title: 'Customer information',
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _kv('Name', args.customerName),
                  _kv('Email', args.customerEmail),
                  _kv('Phone', args.customerPhone),
                ]),
          ),
          _Section(
            title: 'Rewards points',
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rewardsLabel, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Row(children: [
                Switch(
                  value: _useRewards,
                  onChanged: (v) {
                    setState(() {
                      _useRewards = v;
                      if (!v)
                        _appliedPoints = 0;
                      else
                        _appliedPoints = maxRedeemable;
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Text('Use rewards to pay'),
              ]),
              if (_useRewards) ...[
                const SizedBox(height: 8),
                Text(
                    'Applying: ${_money(_appliedPoints)} (${_appliedPoints} points)'),
                Slider(
                  min: 0,
                  max: maxRedeemable.toDouble(),
                  divisions: maxRedeemable > 0 ? maxRedeemable : 1,
                  value: _appliedPoints
                      .toDouble()
                      .clamp(0.0, maxRedeemable.toDouble()),
                  onChanged: (v) {
                    setState(() {
                      _appliedPoints = v.round();
                    });
                  },
                ),
              ]
            ]),
          ),
          _Section(
            title: 'Payment method',
            trailing: const Icon(Icons.chevron_right),
            subtitle: _paymentLabel == null && totalAfterRewards > 0
                ? Row(children: const [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                    SizedBox(width: 6),
                    Text('Payment is required',
                        style: TextStyle(color: Colors.orange)),
                  ])
                : null,
            onTap: _pickPaymentMethod,
            child: Row(
              children: [
                _paymentIcon(_paymentType),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_paymentLabel ??
                      (totalAfterRewards == 0
                          ? 'No payment required (covered by rewards)'
                          : 'Tap to add a method')),
                ),
              ],
            ),
          ),
          _Section(
            title: 'Order summary',
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _kv('Subtotal', _money(subtotal)),
                  _kv('Estimated Tax', _money(taxCents)),
                  const SizedBox(height: 8),
                  if (_useRewards && _appliedPoints > 0)
                    _kv('Rewards applied', _money(_appliedPoints)),
                  const SizedBox(height: 4),
                  _kv('Total', _money(totalAfterRewards), bold: true),
                ]),
          ),
          const SizedBox(height: 84),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: canPlace ? () => _placeOrder() : null,
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

/// ------- UI helpers -------
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.trailing,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final Widget? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEFE9E9))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
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
        Flexible(child: Text(v, textAlign: TextAlign.right, style: style)),
      ],
    ),
  );
}
