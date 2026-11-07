# Community Marketplace

A Flutter community marketplace with a Firebase-backed foundation and existing
screens for browsing, selling, messaging, and profiles.

## Current Firebase integration

- Firebase Core initializes before the Flutter app on Android, iOS, macOS, and
  Web.
- Firebase Authentication handles email/password registration, login, password
  reset, persistent auth state, and logout.
- Firestore stores user profiles and products. Profile editing and listing
  creation, editing, status changes, deletion, and live listing queries are
  connected to Firestore.
- Home listings, search, category browsing, and saved-item views now read
  active products and favorite IDs from Firestore. Favorite changes are saved
  under each user's `users/{uid}/favorites` collection.
- Product details display multiple listing photos in a swipeable carousel with
  animated page indicators and a Hero transition from product cards.
- Buyer-seller conversations and messages use real-time Firestore streams;
  conversation creation and message sending are limited to participants in the
  local Firestore rules.
- Offers can be sent and are persisted in Firestore; only the listing seller can
  accept or reject a pending offer.
- Buyers can save listings in a Firestore cart and submit a single atomic
  pay-in-person order request for up to ten items. Sellers confirm or decline
  requests, advance confirmed orders, and completing an order marks its listing
  sold.
- In-app notifications for new messages, offers, and order events are persisted
  per user in Firestore and can be marked read.
- Seller profiles show their active Firestore listings; the home area label is
  taken from the signed-in profile rather than a hard-coded delivery address.
- Account settings use the signed-in account and provide password-reset email;
  Help & Support explains the current marketplace flow and discloses that
  project-owner support details and legal policies still need to be supplied.
- Profile editing supports selecting and uploading an avatar image to Firebase
  Storage, then saves its URL with the user's Firestore profile.
- Product photos are saved with their listing in Firestore, so listing photos
  do not require a Firebase Storage upgrade. Up to five JPEG, PNG, or WebP
  images are supported per listing; each photo must be at most 600 KB and the
  combined encoded photos must be under 850 KB to stay within Firestore's
  document-size limit.
- Firebase Storage is used for profile-image uploads and is optional for
  browsing and publishing product listings.
- Windows and Linux keep the UI available, but Firebase services are not
  configured for those desktop targets.

Online payment, shipping labels, and delivery tracking are not implemented.
Checkout submits an order request, not a purchase or payment. The buyer and
seller arrange payment in person and coordinate pickup or delivery themselves.
Firebase flows have not been verified against the live project. Push
notifications are not configured; in-app updates appear while the app is open
or when the notification screen next loads.

## Run locally

```bash
flutter pub get
flutter analyze
flutter test --no-test-assets
flutter run -d chrome
```

`--no-test-assets` avoids rebuilding the test asset directory when the project
is stored in a location where that directory is read-only.

## Firebase Console setup

This project uses Firebase project `community-marketplace-ap-1dca8`. Before
testing account flows:

1. In Firebase Console, enable **Email/Password** in
   **Authentication → Sign-in method**.
2. Confirm the project's Cloud Firestore database is available.
3. Firebase Storage is optional for listing photos. Enable it only if you want
   profile-image uploads.
4. Deploy the repository's Firestore and Storage security rules only after
   validating them for your Firebase project.

The Firebase client configuration is generated in
`lib/firebase_options.dart`. Client API keys in Firebase options identify the
app; never add service-account keys or other administrative credentials to this
Flutter project.

To run the local Firebase Auth, Firestore, and Storage emulators, install Java
21 or later and run:

```bash
firebase emulators:start --only auth,firestore,storage --project demo-community-marketplace
```

In a second terminal, run the web app against those local emulators instead of
the configured Firebase project:

```bash
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATORS=true
```

The local emulator ports are Auth `9099`, Firestore `8080`, and Storage `9199`.
With `USE_FIREBASE_EMULATORS=true`, the app uses the same
`demo-community-marketplace` project ID as the emulators, keeping requests
isolated from the live Firebase project. Starting the emulators confirms that
the rules parse, but does not prove that every app operation is authorized. Do
not deploy rules to the live project until their behavior has been tested.
