import 'package:flutter/material.dart';

import 'services/entitlement_service.dart';
// import 'services/revenuecat_entitlement_service.dart'; // switch on for production
import 'screens/shelf_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Demo mode: runs immediately, no store setup, fake purchases. ──
  final EntitlementService entitlements = DemoEntitlementService();

  // ── Production (Google Play Billing via RevenueCat): ──
  // final EntitlementService entitlements = RevenueCatEntitlementService(
  //   apiKey: 'goog_YOUR_ANDROID_PUBLIC_KEY',
  // );

  await entitlements.init();
  runApp(KidsBooksApp(entitlements: entitlements));
}

class KidsBooksApp extends StatelessWidget {
  const KidsBooksApp({super.key, required this.entitlements});

  final EntitlementService entitlements;

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
      home: ShelfScreen(entitlements: entitlements),
    );
  }
}
