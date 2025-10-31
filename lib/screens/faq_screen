import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  // Data: questions + answers
  final List<_FaqItem> _items = [
    _FaqItem(
      q: "What’s the difference between loose-leaf tea and tea bags?",
      a: "Loose-leaf tea uses whole or larger tea leaves that expand fully in water, allowing better flavor, aroma, and nutrient release. Tea bags often contain smaller broken leaves or tea dust, which brews faster but can taste less complex and slightly more bitter.",
    ),
    _FaqItem(
      q: "Are your teas organic, gluten-free or vegan?",
      a: "Most of our blends are naturally vegan and gluten-free. Any organic options are clearly labeled. If you have a specific blend in mind, check its product page or ask us and we’ll confirm.",
    ),
    _FaqItem(
      q: "Does your tea contain caffeine?",
      a: "That depends on the type of tea. Black, oolong, and green teas naturally contain caffeine. Herbal teas such as chamomile, peppermint, and rooibos are naturally caffeine-free, making them perfect for relaxing in the evening.",
    ),
    _FaqItem(
      q: "Can pregnant or breastfeeding women drink your teas?",
      a: "Many of our caffeine-free herbal teas are safe during pregnancy or breastfeeding, such as ginger, peppermint, or rooibos. However, certain herbs should be avoided. Please consult your healthcare provider before trying new blends.",
    ),
    _FaqItem(
      q: "What are the health benefits of herbal teas?",
      a: "Herbal teas are naturally caffeine-free and packed with antioxidants, vitamins, and minerals. They can support digestion, boost relaxation, ease bloating, improve sleep quality, and help with hydration—without added sugar or calories.",
    ),
    _FaqItem(
      q: "Which teas are caffeine-free?",
      a: "Herbal teas such as chamomile, peppermint, hibiscus, rooibos, and fruit blends are caffeine-free.",
    ),
    _FaqItem(
      q: "How do I place an order online?",
      a: "Browse our online tea catalog, add your favorites to the cart, and proceed to checkout. Once your order is confirmed, you can pick it up at Jivan Swad Tea.",
    ),
    _FaqItem(
      q: "Do you add any artificial flavors or preservatives?",
      a: "No, we believe tea should be pure and natural. All our blends are free from artificial flavors, colors, and preservatives. Any added ingredients—fruits, flowers, or spices—are 100% natural and ethically sourced.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bannerBg = const Color(0xFFF4EAE3); // soft beige like your screenshot
    final tileBg = const Color(0xFFFAF6F3);   // very light card background
    final divider = const Color(0xFFEFE7E2);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Banner
              Container(
                width: double.infinity,
                color: bannerBg,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: Column(
                  children: const [
                    Text(
                      "FAQS",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Need some answers?",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // FAQ List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  children: List.generate(_items.length, (i) {
                    final item = _items[i];
                    return Column(
                      children: [
                        _FaqTile(
                          background: tileBg,
                          dividerColor: divider,
                          question: item.q,
                          answer: item.a,
                          expanded: item.expanded,
                          onToggle: () => setState(() {
                            _items[i] = item.copyWith(expanded: !item.expanded);
                          }),
                        ),
                        if (i != _items.length - 1)
                          Container(
                            height: 14, // spacing that looks like the screenshot’s gap
                            color: Colors.transparent,
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.background,
    required this.dividerColor,
    required this.question,
    required this.answer,
    required this.expanded,
    required this.onToggle,
  });

  final Color background;
  final Color dividerColor;
  final String question;
  final String answer;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: dividerColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: question + +
              Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Plus icon (changes to minus when expanded)
                  AnimatedRotation(
                    turns: expanded ? 0.125 : 0, // rotate + to look like × when open
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      expanded ? Icons.remove : Icons.add,
                      size: 20,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),

              // Answer
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    answer,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.black87,
                    ),
                  ),
                ),
                crossFadeState: expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  final String q;
  final String a;
  final bool expanded;
  _FaqItem({required this.q, required this.a, this.expanded = false});

  _FaqItem copyWith({String? q, String? a, bool? expanded}) =>
      _FaqItem(q: q ?? this.q, a: a ?? this.a, expanded: expanded ?? this.expanded);
}
