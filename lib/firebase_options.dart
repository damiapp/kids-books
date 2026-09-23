import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for Peekado.
///
/// These are PLACEHOLDER values — sign-in will fail with "API key not
/// valid" until you swap them for your own project's config. Get them from
/// the Firebase console: Project settings → General → Your apps → the
/// Android app's config values (or read them straight out of a downloaded
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Android '
          '(this app is Android-first — see README).',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    // Web API key, from Project settings → General.
    apiKey: 'YOUR_FIREBASE_ANDROID_API_KEY',
    // Only exists once the Android app is registered against the package
    // name app.peekado. Looks like 1:598826488581:android:....
    appId: 'YOUR_FIREBASE_ANDROID_APP_ID',
    messagingSenderId: '598826488581',
    projectId: 'peekadoo-6529c',
    // Note the domain: projects created since late 2024 get
    // .firebasestorage.app, not the older .appspot.com.
    storageBucket: 'peekadoo-6529c.firebasestorage.app',
  );
}
