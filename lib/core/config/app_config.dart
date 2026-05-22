/// Build-time configuration (align with `tekeraheza-frontend` `VITE_GOOGLE_CLIENT_ID`).
///
/// Run with:
/// `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com`
///
/// Use the **Web application** OAuth client ID from Google Cloud Console so the
/// backend receives a verifiable `idToken`.
class AppConfig {
  AppConfig._();

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static bool get isGoogleSignInConfigured =>
      googleServerClientId.isNotEmpty;
}
