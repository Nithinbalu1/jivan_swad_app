# Jivan Swad Tea - Modern UI Update

## What Changed

I've created a modern, polished customer interface inspired by the screenshots you shared. The new UI includes:

### New Screens

1. **CustomerHomeModern** (`lib/screens/customer_home_modern.dart`)
   - Hero banner with "Stay up to date and order your favorites"
   - Featured items grid with card-based layout
   - Bottom navigation bar (Home / Menu / Profile)
   - Location selector in app bar
   - Floating cart badge

2. **MenuBrowseScreen** (`lib/screens/menu_browse_screen.dart`)
   - "Browse the menu and place an order" header
   - Category filters (All, Coffee, Tea, Hot/Cold Milk, etc.)
   - Location and time selection
   - Featured items list with images and descriptions
   - Item detail modal

3. **LocationScreen** (`lib/screens/location_screen.dart`)
   - "From your favorite location" header
   - Search bar for finding closest location
   - Store cards with:
     - Store name and address
     - Phone number
     - Status (Open/Closed)
     - Pickup option indicator
     - Order button

4. **ItemDetailsSheet** (modal bottom sheet)
   - Item name and description
   - Quantity selector with +/- buttons
   - Size selector (8oz, 12oz, 16oz, 24oz - Hot/Iced)
   - Milk options (Whole, Non Fat, etc.)
   - "Add to Cart" button with dynamic pricing

### Design Features

- **Color Scheme**: Teal/cyan primary color (#4DB5BD) matching the reference screenshots
- **Typography**: Bold headers, clean readable body text
- **Cards**: Rounded corners (12-16px), subtle elevation
- **Spacing**: Generous padding and margins for breathing room
- **Icons**: Material Icons with proper sizing
- **Cart Badge**: Shows item count on menu icon and floating action button

### How to Use the New UI

**Option 1: Replace the current customer home (recommended)**

Edit `lib/main.dart` line 105:
```dart
// Change this:
return const CustomerHome();

// To this:
return const CustomerHomeModern();
```

Then add the import at the top:
```dart
import 'package:jivan_swad_app/screens/customer_home_modern.dart';
```

**Option 2: Keep both and add a toggle**

You can add a settings option or environment flag to switch between the classic and modern UI.

### Running the App

```powershell
# Standard run
flutter run -d chrome

# With Firebase emulators (if you have sample data)
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATORS=true
```

### Demo Data

The new screens include demo/fallback data so the UI looks good even when Firestore is empty:
- Honey & Cinnamon Latte - $5.25
- Bacon, Avocado Egg & Cheese - $9.42
- Caramel Latte - $5.75
- Drip Coffee To-Go - $3.25

### What Still Works

✅ Firebase Auth and role-based routing
✅ Cart functionality with add/remove
✅ Payment simulator integration
✅ Order placement to Firestore
✅ Admin/Provider dashboard (unchanged)
✅ All existing tests pass

### Known Limitations

- Radio button deprecation warnings (Flutter SDK issue, non-blocking)
- `withOpacity` deprecation (use `.withValues()` in newer Flutter versions)
- Location data is currently hardcoded (Barton Rd Stell, Ford St Stell)

### Next Steps (Optional)

1. **Add real item images**: Update Firestore `teas` collection with `imageUrl` field
2. **Implement categories**: Add `category` field to items (Coffee, Tea, Breakfast, etc.)
3. **Add delivery**: Extend location screen with delivery option
4. **Order history**: Create a screen showing past orders for customers
5. **Favorites**: Let customers save favorite items
6. **Customization**: Expand item details with more options (milk type, sweetness, etc.)

### Files Modified

- Created: `lib/screens/customer_home_modern.dart`
- Created: `lib/screens/menu_browse_screen.dart`
- Created: `lib/screens/location_screen.dart`
- No changes to existing files (backward compatible)

## Screenshots Reference

The UI is based on the Stell coffee ordering app screenshots you provided, adapted for the Jivan Swad tea brand.
