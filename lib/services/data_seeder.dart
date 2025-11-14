import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class to seed initial data into Firestore
class DataSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Adds sample tea items to the Firestore 'teas' collection
  static Future<void> seedTeas() async {
    final teas = [
      {
        'name': 'Tulsi Honey Chai',
        'price': 5.25,
        'description': 'A soothing tulsi chai with honey and warming spices',
        'category': 'Tea',
        'available': true,
      },
      {
        'name': 'Masala Chai',
        'price': 4.75,
        'description':
            'Traditional Indian spiced tea with aromatic spices including cardamom, ginger, and cinnamon',
        'category': 'Tea',
        'available': true,
      },
      {
        'name': 'Matcha Green Tea',
        'price': 5.50,
        'description': 'Smooth matcha with a creamy finish',
        'category': 'Tea',
        'available': true,
      },
      {
        'name': 'Lemongrass Green',
        'price': 5.75,
        'description': 'Bright lemongrass with refreshing green tea',
        'category': 'Tea',
        'available': true,
      },
      {
        'name': 'Earl Grey Tea',
        'price': 4.25,
        'description': 'Classic black tea infused with bergamot oil',
        'category': 'Tea',
        'available': true,
      },
      {
        'name': 'Iced Hibiscus',
        'price': 4.50,
        'description': 'Tart and floral hibiscus iced tea over ice',
        'category': 'Tea',
        'available': true,
      },
      {
        'name': 'Ginger Lemon Tea',
        'price': 4.50,
        'description': 'Warming ginger tea with fresh lemon and honey',
        'category': 'Tea',
        'available': true,
      },
      {
        'name': 'Earl Grey',
        'price': 5.00,
        'description': 'Bergamot-infused black tea, a classic favorite',
        'category': 'Tea',
        'available': true,
      },
      {
        'name': 'Chocolate Milk',
        'price': 3.75,
        'description': 'Creamy chocolate milk made with premium cocoa',
        'category': 'Hot/Cold Milk',
        'available': true,
      },
      {
        'name': 'Breakfast Croissant',
        'price': 6.50,
        'description':
            'Buttery croissant with egg, cheese, and choice of bacon or ham',
        'category': 'Breakfast',
        'available': true,
      },
      {
        'name': 'Blueberry Muffin',
        'price': 3.50,
        'description': 'Fresh-baked muffin loaded with blueberries',
        'category': 'Bakery',
        'available': true,
      },
      {
        'name': 'Turkey Sandwich',
        'price': 8.50,
        'description':
            'Roasted turkey with lettuce, tomato, and mayo on whole wheat',
        'category': 'Lunch/Dinner',
        'available': true,
      },
    ];

    try {
      final batch = _db.batch();
      for (var tea in teas) {
        final docRef = _db.collection('teas').doc();
        batch.set(docRef, tea);
      }
      await batch.commit();
      print('✅ Successfully seeded ${teas.length} tea items!');
    } catch (e) {
      print('❌ Error seeding teas: $e');
      rethrow;
    }
  }

  /// Checks if teas collection is empty and seeds if needed
  static Future<bool> seedIfEmpty() async {
    try {
      final snapshot = await _db.collection('teas').limit(1).get();
      if (snapshot.docs.isEmpty) {
        print('📦 Teas collection is empty, seeding data...');
        await seedTeas();
        return true;
      } else {
        print('✅ Teas collection already has data');
        return false;
      }
    } catch (e) {
      print('❌ Error checking/seeding data: $e');
      return false;
    }
  }
}
