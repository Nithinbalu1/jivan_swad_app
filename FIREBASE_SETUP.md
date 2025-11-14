# Firebase Setup Guide for Jivan Swad App

## Quick Setup Steps

### 1. Enable Firebase Services

In Firebase Console (https://console.firebase.google.com):

1. **Authentication**
   - Go to Authentication → Sign-in method
   - Enable "Email/Password" provider
   - Click "Save"

2. **Cloud Firestore**
   - Go to Firestore Database
   - Click "Create database"
   - Start in **production mode** (we'll add rules next)
   - Choose your region

### 2. Set Up Firestore Security Rules

Go to Firestore Database → Rules tab and replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is admin
    function isAdmin() {
      return request.auth != null && 
             exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Helper function to check if user is authenticated
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Teas/Menu Items Collection
    match /teas/{teaId} {
      // Anyone authenticated can read menu
      allow read: if isSignedIn();
      // Only admins can create/update/delete items
      allow write: if isAdmin();
    }
    
    // Orders Collection
    match /orders/{orderId} {
      // Users can read their own orders, admins can read all
      allow read: if isSignedIn() && 
                    (resource.data.customerId == request.auth.uid || isAdmin());
      // Any authenticated user can create an order
      allow create: if isSignedIn() && 
                      request.resource.data.customerId == request.auth.uid;
      // Only admins can update orders (change status, etc.)
      allow update: if isAdmin();
      // Only admins can delete orders
      allow delete: if isAdmin();
    }
    
    // Users Collection (stores user roles)
    match /users/{userId} {
      // Users can read their own data, admins can read all
      allow read: if isSignedIn() && 
                    (request.auth.uid == userId || isAdmin());
      // Users can only write to their own document
      allow write: if isSignedIn() && request.auth.uid == userId;
    }
  }
}
```

**Click "Publish"** to activate the rules.

### 3. Create Admin User

#### Option A: Through Firebase Console (Recommended)

1. **Create Authentication User**
   - Go to Authentication → Users
   - Click "Add user"
   - Enter email: `admin@jivanswad.com`
   - Enter password: (your secure password)
   - Click "Add user"
   - **Copy the User UID** (looks like: `xYz123AbC456...`)

2. **Add Admin Role**
   - Go to Firestore Database
   - Click "Start collection"
   - Collection ID: `users`
   - Document ID: (paste the User UID you copied)
   - Add fields:
     ```
     email (string): admin@jivanswad.com
     role (string): admin
     ```
   - Click "Save"

#### Option B: Through App Code

Add this temporary code to `lib/main.dart` after Firebase initialization:

```dart
// TEMPORARY - Remove after creating admin
Future<void> createAdminUser() async {
  try {
    // Create auth user
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: 'admin@jivanswad.com',
      password: 'YourSecurePassword123!',
    );
    
    // Add admin role to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user!.uid)
        .set({
      'email': 'admin@jivanswad.com',
      'role': 'admin',
    });
    
    print('✅ Admin user created successfully!');
  } catch (e) {
    print('Error: $e');
  }
}

// Call it in main():
Future<void> main() async {
  // ... existing Firebase initialization ...
  
  // TEMPORARY - Uncomment to create admin, then remove
  // await createAdminUser();
  
  runApp(const MyApp());
}
```

### 4. Test Your Setup

1. **Test Customer Login**
   ```bash
   flutter run
   ```
   - Register a new user (they'll be a customer by default)
   - You should see the modern home screen
   - Try browsing menu, adding to cart

2. **Test Admin Login**
   - Logout
   - Login with admin credentials
   - You should see the Provider Dashboard
   - Try managing orders and teas

### 5. Verify Data Seeding

On first app launch, sample menu items are automatically added:
- 12 sample items across 6 categories
- Check Firestore → `teas` collection to verify

If data didn't seed automatically:
```dart
// Run this once from anywhere in your app
import 'package:jivan_swad_app/services/data_seeder.dart';

await DataSeeder.seedTeas();
```

## Firestore Collections Structure

### `teas` Collection
```
teas/
  {auto-id}/
    - name: "Masala Chai"
    - price: 4.75
    - description: "Traditional Indian spiced tea..."
    - category: "Tea"
    - available: true
```

### `orders` Collection
```
orders/
  {auto-id}/
    - customerName: "user@example.com"
    - customerId: "xyz123..."
    - total: 15.50
    - status: "pending"
    - location: "Barton Rd Stell"
    - createdAt: Timestamp
    - items: [
        {teaId: "abc", name: "Masala Chai", qty: 2, price: 4.75}
      ]
```

### `users` Collection
```
users/
  {user-uid}/
    - email: "user@example.com"
    - role: "customer" or "admin"
```

## Security Rules Explanation

### Read Access
- **Teas**: Any authenticated user can read menu
- **Orders**: Users see only their orders; admins see all
- **Users**: Users see only their profile; admins see all

### Write Access
- **Teas**: Only admins can add/edit/delete menu items
- **Orders**: 
  - Customers can create their own orders
  - Only admins can update order status
  - Only admins can delete orders
- **Users**: Users can only modify their own profile

## Troubleshooting

### "Permission Denied" Error

**Problem**: App shows demo data or "Failed to load" messages

**Solution**:
1. Check Firebase Console → Firestore → Rules
2. Verify rules are published (not in draft)
3. Check Authentication → Users (make sure user exists)
4. Verify user has entry in `users` collection with `role` field

### Admin Can't Access Dashboard

**Problem**: Admin user sees customer screen instead

**Solution**:
1. Verify `users/{uid}` document exists with correct UID
2. Check `role` field is exactly `"admin"` (lowercase)
3. Logout and login again
4. Check browser console for errors

### Data Not Seeding

**Problem**: Menu is empty after first launch

**Solution**:
1. Check Firestore rules allow write access
2. Manually run `DataSeeder.seedTeas()` from dev console
3. Or manually add items through admin dashboard

### Orders Not Saving

**Problem**: "Order failed" message when placing order

**Solution**:
1. Verify `orders` collection rules allow create
2. Check `customerId` field matches authenticated user UID
3. Ensure `users/{uid}` document exists

## Production Checklist

Before deploying to production:

- [ ] Update Firebase security rules (remove test accounts)
- [ ] Remove data seeding code (or make it admin-only)
- [ ] Set up Firebase billing (if using paid tier)
- [ ] Enable Firebase App Check for API security
- [ ] Set up Cloud Functions for order notifications
- [ ] Configure email verification for new users
- [ ] Add rate limiting to prevent abuse
- [ ] Set up monitoring and alerts
- [ ] Configure backup schedule for Firestore
- [ ] Update privacy policy and terms of service

## Support

If you encounter issues:
1. Check Firebase Console → Analytics → Debug View
2. Enable debug logging in app
3. Check browser/device console for errors
4. Verify network connectivity
5. Test with Firebase Emulator Suite for local testing

---

**Next Steps**: See [README_PRODUCTION.md](./README_PRODUCTION.md) for full app documentation.
