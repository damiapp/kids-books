import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for Peekadoo.
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
    apiKey: 'AIzaSyDxBRrq7vLSND7eeHqwk0ymMge7lyNnsfo',
    appId: '1:857741802405:android:a3de21aaf1be731e85464c',
    messagingSenderId: '857741802405',
    projectId: 'peekadoo-c5c2d',
    // Note the domain: projects created since late 2024 get
    // .firebasestorage.app, not the older .appspot.com.
    storageBucket: 'peekadoo-c5c2d.firebasestorage.app',
  );
}
