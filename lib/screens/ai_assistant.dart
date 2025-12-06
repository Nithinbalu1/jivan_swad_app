import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AIAssistantScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Map<String, int> cart;
  final void Function(String itemId)? onAddToCart;

  const AIAssistantScreen({
    super.key,
    required this.items,
    required this.cart,
    this.onAddToCart,
  });

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _search = TextEditingController();
  final TextEditingController _input = TextEditingController();

  final List<Map<String, String>> _messages = [];
  // Firebase support: only sync chat for customer users
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<User?>? _authSub;
  String? _userId;
  bool _isCustomer = false;
  static const String _thinkingText = 'Thinking...';

  // Proxy URL used by the app. Use localhost for web, and emulator host for Android.
  static String get proxyUrl {
    if (kIsWeb) return 'http://localhost:8787/api/ai/chat';
    // Android emulator mapping; update when testing on a real device or iOS simulator.
    return 'http://10.0.2.2:8787/api/ai/chat';
  }

  // Built-in FAQ
  final List<Map<String, String>> _faq = [
    {
      'q': 'How do I place an order?',
      'a': 'Add items to the cart and tap Place Order.'
    },
    {
      'q': 'Can I cancel an order?',
      'a': 'Orders can be cancelled from dashboard when pending.'
    },
    {
      'q': 'How do I add new items (admin)?',
      'a': 'Admins can go to Manage Teas → Add Item.'
    },
    {
      'q': 'Why am I seeing demo items?',
      'a': 'Demo items appear when Firestore is unavailable.'
    },
  ];

  List<Map<String, dynamic>> get _items => widget.items.isNotEmpty
      ? widget.items
      : [
          {'id': 'a', 'name': 'A Tea', 'price': 49.0, 'description': 'Demo A'},
          {'id': 'b', 'name': 'B Tea', 'price': 59.0, 'description': 'Demo B'},
          {'id': 'c', 'name': 'C Tea', 'price': 69.0, 'description': 'Demo C'},
        ];

  List<Map<String, dynamic>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _buildRecommendations();
    // Listen for auth changes so we start/stop chat sync when users sign in/out.
    _authSub = _auth.authStateChanges().listen((_) => _initChatSync());
    // Initialize sync state for current user (if any).
    _initChatSync();
  }

  void _initChatSync() {
    // Stop any existing subscription first.
    _messagesSub?.cancel();
    _messagesSub = null;
    _userId = null;
    _isCustomer = false;
    setState(() {
      _messages.clear();
    });

    final user = _auth.currentUser;
    if (user == null) return; // not signed in — keep local-only

    // Check user's role in Firestore; only customers should have chat synced.
    _userId = user.uid;
    _db.collection('users').doc(_userId).get().then((doc) {
      final role = (doc.data() ?? {})['role']?.toString() ?? '';
      _isCustomer = role == 'customer';
      if (!_isCustomer) return; // do not subscribe for non-customers

      final col =
          _db.collection('ai_chats').doc(_userId).collection('messages');
      _messagesSub = col
          .orderBy('createdAt', descending: false)
          .snapshots()
          .listen((snap) {
        final docs = snap.docs;
        setState(() {
          _messages.clear();
          for (var d in docs) {
            final role = (d.data()['role'] ?? 'bot').toString();
            final text = (d.data()['text'] ?? '').toString();
            _messages
                .add({'from': role == 'user' ? 'user' : 'bot', 'text': text});
          }
        });
      });
    }).catchError((e) {
      print('Failed to determine user role for chat sync: $e');
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _input.dispose();
    _messagesSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  // Query the server proxy which performs upstream calls (OpenAI / Ollama).
  Future<String?> _queryAi(String prompt) async {
    final url = Uri.parse(proxyUrl);
    try {
      // Increase timeout to allow slower upstream providers (e.g. Ollama).
      final resp = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"prompt": prompt}),
          )
          .timeout(const Duration(seconds: 60));

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final answer = json["answer"];
        return answer?.toString().trim();
      } else {
        print("Proxy error ${resp.statusCode}: ${resp.body}");
        return null;
      }
    } catch (e) {
      print("Proxy exception: $e");
      return null;
    }
  }

  // Build a contextual prompt that includes app-specific information (catalog,
  // recommendations) so the AI produces answers grounded in the app data.
  String _buildPrompt(String userText) {
    // Use up to the first 10 items to avoid very long prompts.
    final items = _items.take(10).map((it) {
      final id = it['id']?.toString() ?? '';
      final name = it['name']?.toString() ?? '';
      final price = it['price']?.toString() ?? '';
      final desc = it['description']?.toString() ?? '';
      return '- $name (id:$id) — ₹$price — $desc';
    }).toList();

    final catalog = items.isEmpty ? 'No items available.' : items.join('\n');

    final header = StringBuffer();
    header.writeln('You are the Jivan Swad app assistant.');
    header.writeln(
        'App description: Jivan Swad is a tea catalog and ordering app. Users can browse teas, add to cart, and place orders. Authentication is via Firebase.');
    header.writeln(
        'Use the app catalog below to answer user questions and give product recommendations.');
    header.writeln(
        'When recommending, prefer items that match the user intent and include item id and price.');
    header.writeln('\nCatalog:\n$catalog');
    header.writeln('\nUser question:');
    header.writeln(userText);
    header.writeln(
        '\nRespond concisely. If the question asks for a list or recommendations, return a short numbered list referencing item names and ids.');

    return header.toString();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({'from': 'user', 'text': text});
    });
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add({'from': 'bot', 'text': text});
    });
  }

  // Local fallback reply
  String _generateReply(String msg) {
    final low = msg.toLowerCase();

    for (var f in _faq) {
      if (low.contains(f['q']!.split(" ").first.toLowerCase())) return f['a']!;
    }

    return 'Sorry, I didn’t understand. Try asking about ordering or menu.';
  }

  Future<void> _handleSend() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    _input.clear();
    // If user is signed in and a customer, write message to Firestore so chats sync across devices.
    if (_userId != null && _isCustomer) {
      try {
        final col =
            _db.collection('ai_chats').doc(_userId).collection('messages');
        await col.add({
          'role': 'user',
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // fallback to local add
        _addUserMessage(text);
      }

      // Show temporary thinking locally for responsiveness
      _addBotMessage(_thinkingText);

      final prompt = _buildPrompt(text);
      final aiReply = await _queryAi(prompt);

      // Remove local thinking placeholder (if still present)
      setState(() {
        if (_messages.isNotEmpty && _messages.last['text'] == _thinkingText) {
          _messages.removeLast();
        }
      });

      final replyText = (aiReply != null && aiReply.isNotEmpty)
          ? aiReply
          : 'AI is unavailable right now.';

      // Persist bot reply to Firestore so it syncs
      try {
        final col =
            _db.collection('ai_chats').doc(_userId).collection('messages');
        await col.add({
          'role': 'bot',
          'text': replyText,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // fallback: show locally
        _addBotMessage(replyText);
      }
      return;
    }

    // Not signed in: local-only flow
    _addUserMessage(text);

    // Show temporary thinking message
    _addBotMessage(_thinkingText);

    final prompt = _buildPrompt(text);
    final aiReply = await _queryAi(prompt);

    // Remove "Thinking..."
    setState(() {
      if (_messages.isNotEmpty && _messages.last['text'] == _thinkingText) {
        _messages.removeLast();
      }
    });

    if (aiReply != null && aiReply.isNotEmpty) {
      _addBotMessage(aiReply);
    } else {
      _addBotMessage("AI is unavailable right now.");
    }
  }

  // Recommendations
  void _buildRecommendations() {
    final items = _items;
    final cartIds = widget.cart.keys.toSet();

    final List<Map<String, dynamic>> recs = [];

    if (cartIds.isNotEmpty) {
      final cartNames = <String>[];
      for (var id in cartIds) {
        final found =
            items.firstWhere((it) => it['id'] == id, orElse: () => {});
        if (found['name'] != null) cartNames.add(found['name']);
      }

      final words = cartNames
          .expand((e) => e.split(' '))
          .map((e) => e.toLowerCase())
          .toSet();

      for (var it in items) {
        if (cartIds.contains(it['id'])) continue;
        final name = (it['name'] ?? '').toLowerCase();
        if (words.any((w) => name.contains(w))) recs.add(it);
      }
    }

    if (recs.isEmpty) {
      final fallback = List<Map<String, dynamic>>.from(items)
        ..sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
      recs.addAll(fallback.take(3));
    }

    _recommendations = recs;
  }

  List<Map<String, String>> get _filteredFaq {
    final q = _search.text.toLowerCase();
    if (q.isEmpty) return _faq;
    return _faq
        .where((f) =>
            f['q']!.toLowerCase().contains(q) ||
            f['a']!.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search FAQ or ask a question',
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 12),

            // Chat UI
            Container(
              height: 240,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _messages.isEmpty
                        ? const Center(child: Text("Ask me anything..."))
                        : ListView.builder(
                            reverse: true,
                            itemCount: _messages.length,
                            itemBuilder: (_, idx) {
                              final m = _messages[_messages.length - 1 - idx];
                              final fromUser = m["from"] == "user";

                              return Align(
                                alignment: fromUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: fromUser
                                        ? Colors.blueAccent
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    m["text"] ?? "",
                                    style: TextStyle(
                                      color: fromUser
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          decoration:
                              const InputDecoration(hintText: "Type message"),
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _handleSend,
                      )
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: [
                  const Text("FAQ",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ..._filteredFaq.map((f) => Card(
                        child: ListTile(
                          title: Text(f["q"]!),
                          subtitle: Text(f["a"]!),
                        ),
                      )),
                  const SizedBox(height: 16),
                  const Text("Recommended for you",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ..._recommendations.map((it) => Card(
                        child: ListTile(
                          title: Text(it["name"].toString()),
                        ),
                      )),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
