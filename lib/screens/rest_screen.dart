import 'package:flutter/material.dart';

import '../data/lesson_catalog.dart';
import '../services/energy_service.dart';
import '../services/entitlement_service.dart';
import '../services/narration_service.dart';
import '../services/progress_service.dart';
import '../widgets/motion.dart';
import '../widgets/parental_gate.dart';
import 'lesson_screen.dart';
import 'paywall_screen.dart';
import 'word_bank_screen.dart';

/// What a child sees when energy runs out — instead of a paywall.
///
/// It used to be a dialog offering a subscription, shown to a
/// three-year-old mid-session. For them that's a wall with no way past it;
/// for a parent watching, it reads as an app built to extract money from
/// toddlers. Neither is the audience a purchase should be pitched to.
///
/// So the child gets a rest, said kindly and out loud, and two things they
/// can still do — both already free: the words they've learned, and
/// practice on the ones that tripped them up. The subscription is still
/// here, but behind a parent check, labelled for grown-ups.
class RestScreen extends StatefulWidget {
  const RestScreen({
    super.key,
    required this.progress,
    required this.energy,
    required this.entitlements,
  });

  final ProgressService progress;
  final EnergyService energy;
  final EntitlementService entitlements;

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  final _narration = NarrationService();

  @override
  void initState() {
    super.initState();
    // After the route has settled, so the first words aren't lost under
    // the transition.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _narration.speak(
          'Your energy is having a little rest. You can still play with '
          'your words!');
    });
  }

  @override
  void dispose() {
    _narration.dispose();
    super.dispose();
  }

  void _open(Widget screen) {
    _narration.stop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openGrownUps() async {
    _narration.stop();
    if (!await ParentalGate.show(context) || !mounted) return;
    _open(PaywallScreen(entitlements: widget.entitlements));
  }

  @override
  Widget build(BuildContext context) {
    final drill = LessonCatalog.practiceLesson(widget.progress.trickiestWords);
    final wait = widget.energy.timeUntilNext;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF6),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            children: [
              const Spacer(),
              const PopIn(
                from: 0.4,
                child: Bob(
                  height: 5,
                  child: Text('😴', style: TextStyle(fontSize: 92)),
                ),
              ),
              const SizedBox(height: 16),
              const PopIn(
                delay: Duration(milliseconds: 150),
                child: Text(
                  'Time for a little rest',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 8),
              PopIn(
                delay: const Duration(milliseconds: 250),
                child: Text(
                  wait == null
                      ? 'More energy is on its way.'
                      : 'More energy in about ${_minutes(wait)}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7A756B),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              PopIn(
                delay: const Duration(milliseconds: 350),
                child: _BigChoice(
                  emoji: '📖',
                  label: 'My words',
                  color: const Color(0xFFD8F0CE),
                  onTap: () =>
                      _open(WordBankScreen(progress: widget.progress)),
                ),
              ),
              if (drill != null) ...[
                const SizedBox(height: 14),
                PopIn(
                  delay: const Duration(milliseconds: 450),
                  child: _BigChoice(
                    emoji: '🎯',
                    label: 'Tricky words',
                    color: const Color(0xFFFFDBC2),
                    onTap: () => _open(LessonScreen(
                      progress: widget.progress,
                      lesson: drill,
                      isPractice: true,
                    )),
                  ),
                ),
              ],
              const Spacer(),
              // Small and plainly worded: a parent finds it, a child
              // doesn't mistake it for the next thing to play.
              TextButton(
                onPressed: _openGrownUps,
                child: const Text('For grown-ups: unlimited energy'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _minutes(Duration d) {
  final minutes = d.inMinutes + (d.inSeconds % 60 > 0 ? 1 : 0);
  return minutes <= 1 ? 'a minute' : '$minutes minutes';
}

/// A choice made for a child: led by a picture, big enough for a small
/// thumb, and one word long.
class _BigChoice extends StatelessWidget {
  const _BigChoice({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 80,
            width: double.infinity,
            child: Row(
              children: [
                const SizedBox(width: 20),
                Text(emoji, style: const TextStyle(fontSize: 38)),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
