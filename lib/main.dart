import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/energy_service.dart';
import 'services/entitlement_service.dart';
import 'services/progress_service.dart';
// import 'services/revenuecat_entitlement_service.dart'; // switch on for production
import 'screens/landing_screen.dart';
import 'screens/path_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final auth = AuthService();
  final progress = ProgressService();
  final energy = EnergyService();

  // ── Demo mode: runs immediately, no store setup, fake purchases. ──
  final EntitlementService entitlements = DemoEntitlementService();

  // ── Production (Google Play Billing via RevenueCat): ──
  // final EntitlementService entitlements = RevenueCatEntitlementService(
  //   apiKey: 'goog_YOUR_ANDROID_PUBLIC_KEY',
  // );

  await entitlements.init();
  await progress.init();
  await energy.init();
  runApp(PeekadoApp(
    entitlements: entitlements,
    auth: auth,
    progress: progress,
    energy: energy,
  ));
}

class PeekadoApp extends StatelessWidget {
  const PeekadoApp({
    super.key,
    required this.entitlements,
    required this.auth,
    required this.progress,
    required this.energy,
  });

  final EntitlementService entitlements;
  final AuthService auth;
  final ProgressService progress;
  final EnergyService energy;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peekado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3AA7A0),
        scaffoldBackgroundColor: const Color(0xFFFDFBF6),
      ),
      // Signed in → straight to the path. Signed out → landing page, which
      // leads through the onboarding slides into sign-in.
      home: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          return auth.isSignedIn
              ? PathScreen(
                  entitlements: entitlements,
                  auth: auth,
                  progress: progress,
                  energy: energy,
                )
              : LandingScreen(
                  entitlements: entitlements,
                  auth: auth,
                  progress: progress,
                  energy: energy,
                );
        },
      ),
    );
  }
}
