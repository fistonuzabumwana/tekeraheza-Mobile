# Tekeraheza Mobile (Flutter)

## API

Default base URL is set in `lib/core/api/api_constants.dart` (AWS EC2).

## Google Sign-In (same as web `VITE_GOOGLE_CLIENT_ID`)

Use the **Web application** OAuth 2.0 client ID from [Google Cloud Console](https://console.cloud.google.com/apis/credentials) (the same type as the frontend’s Google login).

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_ID.apps.googleusercontent.com
```

**Android:** Add your debug/release **SHA-1** to that OAuth client (or a linked Android client) or the ID token may be empty.

**iOS:** Configure URL types per [google_sign_in](https://pub.dev/packages/google_sign_in) if you use Google on iOS.

## Bulk orders CSV

Format (optional header row):

```csv
customerId,productId,quantity,paymentMethod,orderType
```

Omitting header is fine if columns are in that order. `paymentMethod` and `orderType` are optional (default `CASH` and `STANDARD`).
