import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/energy_service.dart';
import '../services/entitlement_service.dart';
import '../services/progress_service.dart';
import 'login_screen.dart';

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.description,
  });

  final String emoji;
  final String title;
  final String description;
}

const _slides = [
  _OnboardingSlide(
    emoji: '🎧',
    title: 'Listen, then try it yourself',
    description: 'Every lesson teaches a word, then asks your child to tap '
        'the picture that matches what they just heard — learning by doing.',
  ),
  _OnboardingSlide(
    emoji: '⚡',
    title: 'Free energy every day',
    description: 'Each lesson uses a little energy, which refills over '
        'time — or go All Access for unlimited energy and new lessons '
        'the moment they land.',
  ),
];

/// Two-slide explainer of what the app does, shown between the landing
/// page and sign-in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
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
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  void _next() {
    if (_index < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LoginScreen(
        entitlements: widget.entitlements,
        auth: widget.auth,
        progress: widget.progress,
        energy: widget.energy,
      ),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: TextButton(
                  onPressed: _goToLogin,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(36),
                          ),
                          child: Text(slide.emoji,
                              style: const TextStyle(fontSize: 72)),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _next,
                  child: Text(
                    isLast ? 'Get Started' : 'Next',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
