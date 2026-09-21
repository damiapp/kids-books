import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for Peekado.
///
/// These are PLACEHOLDER values — sign-in will fail with "API key not
/// valid" until you swap them for your own project's config. Get them from
/// the Firebase console: Project settings → General → Your apps → each
/// registered app's config values (or read them straight out of a downloaded
/// `google-services.json`: `client[0].api_key[0].current_key`,
/// `client[0].client_info.mobilesdk_app_id`, `project_info.project_number`,
/// `project_info.project_id`, `project_info.storage_bucket`).
///
/// Unlike the RevenueCat/Play key elsewhere in this app, Firebase client
/// config is not a secret — it's meant to ship inside the app. Access is
/// controlled by Firebase Auth and security rules, not by hiding these
/// values, so it's fine to commit real ones here.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Android and '
          'iOS (see README §1c).',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_ANDROID_API_KEY',
    appId: 'YOUR_FIREBASE_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_FIREBASE_MESSAGING_SENDER_ID',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    storageBucket: 'YOUR_FIREBASE_PROJECT_ID.appspot.com',
  );

  // A separate app registration in the same Firebase project — an iOS
  // app has its own API key and app id, and needs the bundle id the CI
  // build uses (app.peekado). Values come from GoogleService-Info.plist
  // (API_KEY, GOOGLE_APP_ID, GCM_SENDER_ID, PROJECT_ID).
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_IOS_API_KEY',
    appId: 'YOUR_FIREBASE_IOS_APP_ID',
    messagingSenderId: 'YOUR_FIREBASE_MESSAGING_SENDER_ID',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    storageBucket: 'YOUR_FIREBASE_PROJECT_ID.appspot.com',
    iosBundleId: 'app.peekado',
  );
}
