# Safeguard - Public Emergency Health Response System

A cross-platform Flutter application for emergency health response at Federal University Otuoke (FUO).

## Tech Stack
- **Frontend:** Flutter (Android, iOS, Web)
- **Auth:** Firebase Authentication
- **Database:** Cloud Firestore (NoSQL)
- **State Management:** Flutter Riverpod
- **Location:** Geolocator (mobile) + Browser Geolocation API (web)

## Setup Instructions

### 1. Create Firebase Project
- Go to https://console.firebase.google.com
- Create a new project named "Safeguard"
- Enable Authentication → Email/Password
- Enable Firestore Database → Start in test mode

### 2. Configure Firebase
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
This generates `lib/firebase_options.dart` with your actual keys.

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run the App
```bash
# Web
flutter run -d chrome

# Android
flutter run
```

## Firestore Collections
- `profiles` — user registration and health data
- `sos_alerts` — emergency alert submissions
- `location_history` — GPS location logs
- `notifications` — admin alert notifications

## Firestore Indexes Required
Create these composite indexes in Firebase Console → Firestore → Indexes:
- Collection: `sos_alerts` | Fields: `status ASC, created_at DESC`
- Collection: `notifications` | Fields: `user_id ASC, created_at DESC`
