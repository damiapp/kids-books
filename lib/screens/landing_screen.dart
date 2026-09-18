import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/energy_service.dart';
import '../services/entitlement_service.dart';
import '../services/reading_progress_service.dart';
import 'onboarding_screen.dart';

/// First screen a new visitor sees: app name, tagline, and a way in.
class LandingScreen extends StatelessWidget {
  const LandingScreen({
    super.key,
    required this.entitlements,
    required this.auth,
    required this.progress,
    required this.energy,
  });

  final EntitlementService entitlements;
  final AuthService auth;
  final ReadingProgressService progress;
  final EnergyService energy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Text('📚', style: TextStyle(fontSize: 64)),
              ),
              const SizedBox(height: 28),
              const Text(
                'Story Shelf',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                'Fun daily lessons for curious kids, 3+.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => OnboardingScreen(
                        entitlements: entitlements,
                        auth: auth,
                        progress: progress,
                        energy: energy,
                      ),
                    ));
                  },
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
