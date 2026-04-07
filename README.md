# Inventory App (ICA 12)

Flutter inventory manager backed by **Cloud Firestore**. Items sync in real time using a `StreamBuilder` and a small **service layer** for all CRUD calls.

**Repository:** [github.com/nitesh-kumar-15/inventory-app](https://github.com/nitesh-kumar-15/inventory-app)

## Firebase / configuration

The checkout includes **placeholder** values in `lib/firebase_options.dart` and `android/app/google-services.json.example`. **`android/app/google-services.json`** and **`firebase.json`** are gitignored.

1. In [Firebase Console](https://console.firebase.google.com/), register an Android app with package **`com.example.inventory_app`** (see `android/app/build.gradle.kts`).
2. Download **`google-services.json`** into **`android/app/`**.
3. Run **`flutterfire configure`** from the project root, or replace placeholders in **`lib/firebase_options.dart`** with your project’s values.
4. Enable **Cloud Firestore** for the project.

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) and run `flutter doctor`.
2. Complete the Firebase steps above.
3. `flutter pub get` then `flutter run`.

## Project structure

| Area | Role |
|------|------|
| `lib/models/item.dart` | `Item` with `toMap()` / `fromMap()` |
| `lib/services/inventory_service.dart` | `addItem`, `streamItems`, `updateItem`, `deleteItem` |
| `lib/screens/inventory_screen.dart` | `StreamBuilder` + `ListView.builder`, forms, filters |
| `lib/main.dart` | `Firebase.initializeApp` + app theme |

## Validation

Add/edit form uses `TextFormField` validators:

- **Name** — required (non-empty after trim).
- **Quantity** — required, digits only, whole number, not negative.
- **Price** — required, parseable `double`, not negative.

## Enhanced features

1. **Live name search** — filters the list client-side by item name as you type (on top of the Firestore stream).
2. **Low-stock mode** — items with quantity below **`kLowStockThreshold`** (see `inventory_screen.dart`) show a warning-style icon, a **Low** chip, and a filter chip to show only low-stock rows.

## Knowledge check (ICA 12 hub)

1. Best widget for real-time Firestore updates: **StreamBuilder** (B).  
2. Where CRUD should live: **Dedicated service layer** (B).  
3. Why validate quantity and price: **To prevent invalid data writes** (A).

## Build APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

## Author

Submitted for **In-Class Activity #12** — Mobile App Development.
