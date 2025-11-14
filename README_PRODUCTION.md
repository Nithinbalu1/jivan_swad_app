# Jivan Swad Tea App - Production Ready

A modern, full-featured Flutter application for ordering tea and beverages with Firebase backend.

## ✨ Features

### Customer Features
- **Modern UI**: Polished interface with hero banners, card layouts, and smooth navigation
- **Browse Menu**: Category-based filtering (Coffee, Tea, Hot/Cold Milk, Breakfast, Bakery, Lunch/Dinner)
- **Shopping Cart**: Add/remove items with real-time cart updates
- **Location Selection**: Choose pickup location from available stores
- **Payment Processing**: Integrated payment flow with card validation
- **Order History**: View past orders with detailed information
- **Order Tracking**: See order status (Pending, Preparing, Completed, Cancelled)

### Admin Features
- **Provider Dashboard**: Manage orders and menu items
- **Order Management**: View and update order status
- **Tea Management**: Add, edit, and remove menu items

### Technical Features
- **Firebase Authentication**: Secure user login and registration
- **Cloud Firestore**: Real-time database for orders and menu items
- **Auto Data Seeding**: Automatically populates database with sample items
- **Offline Support**: Graceful handling of network issues
- **Role-Based Access**: Different interfaces for customers and admins

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.4.0)
- Firebase project with Authentication and Firestore enabled
- VS Code or Android Studio

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Nithinbalu1/jivan_swad_app.git
   cd jivan_swad_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at https://console.firebase.google.com
   - Enable Authentication (Email/Password)
   - Enable Cloud Firestore
   - Download and place `google-services.json` in `android/app/`
   - Run `flutterfire configure` to generate Firebase options

4. **Run the app**
   ```bash
   flutter run -d chrome  # For web
   flutter run            # For mobile/desktop
   ```

### Firebase Setup

#### Firestore Security Rules
Update your Firestore rules to allow authenticated users to read/write:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read teas
    match /teas/{teaId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Allow users to read/write their own orders
    match /orders/{orderId} {
      allow read: if request.auth != null && 
                    (resource.data.customerId == request.auth.uid || 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### Creating Admin Users
To create an admin user, add a document to the `users` collection:

```javascript
// In Firestore Console
Collection: users
Document ID: [user's UID from Authentication]
Fields:
  - email: "admin@example.com"
  - role: "admin"
```

## 📱 App Structure

```
lib/
├── main.dart                 # App entry point with routing
├── firebase_options.dart     # Firebase configuration
├── screens/
│   ├── customer_home_modern.dart    # Main customer screen
│   ├── menu_browse_screen.dart      # Menu browsing with filters
│   ├── location_screen.dart         # Store selection
│   ├── review_order.dart            # Order review before payment
│   ├── payment_method.dart          # Payment card entry
│   ├── order_placed.dart            # Order confirmation
│   ├── order_history_screen.dart    # Past orders view
│   └── login_screen.dart            # Authentication
├── provider/
│   ├── provider_home.dart           # Admin dashboard
│   ├── manage_orders.dart           # Order management
│   └── manage_teas.dart             # Menu management
└── services/
    ├── auth_service.dart            # Authentication logic
    ├── payment_simulator.dart       # Payment processing
    └── data_seeder.dart             # Sample data generation
```

## 🎨 Design

### Color Scheme
- **Primary**: Teal/Cyan (#4DB5BD)
- **Background**: Light Gray (#F5F5F5)
- **Cards**: White with subtle shadows
- **Text**: Black87 for primary, Gray600 for secondary

### Key Screens

1. **Home Screen**
   - Hero banner with call-to-action
   - Featured items grid (2 columns)
   - Quick access to orders
   - Bottom navigation (Home, Menu, Profile)

2. **Menu Browse**
   - Horizontal category filters
   - Location/time selector
   - Scrollable item list with images
   - Add to cart from list or details modal

3. **Cart & Checkout**
   - Cart summary with quantities
   - Location selection
   - Payment card entry with validation
   - Order confirmation

4. **Order History**
   - Chronological list of past orders
   - Status badges (Pending, Completed, etc.)
   - Detailed view with item breakdown
   - Total and location information

## 🧪 Testing

### Run Tests
```bash
flutter test
```

### Run with Coverage
```bash
flutter test --coverage
```

### Analyze Code Quality
```bash
flutter analyze
```

## 📊 Data Models

### Tea/Menu Item
```dart
{
  'name': String,
  'price': double,
  'description': String,
  'category': String,  // Coffee, Tea, Hot/Cold Milk, Breakfast, Bakery, Lunch/Dinner
  'available': bool
}
```

### Order
```dart
{
  'customerName': String,
  'customerId': String,
  'total': double,
  'status': String,  // pending, preparing, completed, cancelled
  'location': String,
  'createdAt': Timestamp,
  'items': [
    {
      'teaId': String,
      'name': String,
      'qty': int,
      'price': double
    }
  ]
}
```

### User
```dart
{
  'email': String,
  'role': String,  // 'customer' or 'admin'
}
```

## 🔐 Authentication Flow

1. User opens app → `AuthGate` checks login state
2. If logged in → Check role in Firestore
3. If admin → Show `ProviderHome` (admin dashboard)
4. If customer → Show `CustomerHomeModern`
5. If not logged in → Show `LoginScreen`

## 🛠️ Development

### Adding New Menu Items
The app automatically seeds sample data. To add real items:

1. Log in as admin
2. Navigate to "Manage Teas" section
3. Click "Add Tea" and fill in details
4. Items appear immediately in customer menu

### Customizing Categories
Edit the categories list in `menu_browse_screen.dart`:
```dart
final List<String> _categories = [
  'All',
  'Coffee',
  'Tea',
  'Your Category',
  // Add more categories
];
```

### Payment Integration
The app uses `PaymentSimulator` for demo purposes. To integrate real payments:

1. Replace `payment_simulator.dart` with actual payment gateway
2. Update `review_order.dart` to call real payment API
3. Handle payment webhooks for order confirmation

## 📦 Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  firebase_core: ^3.3.0
  firebase_auth: ^5.1.0
  cloud_firestore: ^5.0.2
  intl: ^0.19.0  # Date formatting
```

## 🐛 Known Issues

- Some deprecation warnings (Flutter SDK evolution, non-critical)
- RadioListTile API changes in Flutter 3.32+
- Color.withOpacity → Color.withValues migration pending

## 🚀 Deployment

### Web
```bash
flutter build web
# Deploy to Firebase Hosting, Netlify, or Vercel
```

### Android
```bash
flutter build apk --release
# Or for app bundle:
flutter build appbundle
```

### iOS
```bash
flutter build ios --release
# Open in Xcode for signing and submission
```

## 📝 License

This project is open source and available under the MIT License.

## 👥 Contributors

- Nithin Balu (@Nithinbalu1)

## 🆘 Support

For issues or questions:
1. Check existing GitHub issues
2. Create a new issue with detailed description
3. Include error logs and screenshots

## 🎯 Roadmap

- [ ] Real payment gateway integration (Stripe/PayPal)
- [ ] Push notifications for order updates
- [ ] User profiles with favorites
- [ ] Rewards/loyalty points system
- [ ] Real-time order tracking map
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] Item images upload to Firebase Storage

---

**Made with ❤️ using Flutter and Firebase**
