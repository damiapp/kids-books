import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/entitlement_service.dart';
// import 'services/revenuecat_entitlement_service.dart'; // switch on for production
import 'screens/landing_screen.dart';
import 'screens/shelf_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final auth = AuthService();

  // ── Demo mode: runs immediately, no store setup, fake purchases. ──
  final EntitlementService entitlements = DemoEntitlementService();

  // ── Production (Google Play Billing via RevenueCat): ──
  // final EntitlementService entitlements = RevenueCatEntitlementService(
  //   apiKey: 'goog_YOUR_ANDROID_PUBLIC_KEY',
  // );

  await entitlements.init();
  runApp(KidsBooksApp(entitlements: entitlements, auth: auth));
}

class KidsBooksApp extends StatelessWidget {
  const KidsBooksApp({super.key, required this.entitlements, required this.auth});

  final EntitlementService entitlements;
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Story Shelf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3AA7A0),
        scaffoldBackgroundColor: const Color(0xFFFDFBF6),
      ),
      // Signed in → straight to the shelf. Signed out → landing page, which
      // leads through the onboarding slides into sign-in.
      home: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          return auth.isSignedIn
              ? ShelfScreen(entitlements: entitlements, auth: auth)
              : LandingScreen(entitlements: entitlements, auth: auth);
        },
      ),
    );
  }
}
