import 'package:flutter/material.dart';

import '../services/energy_service.dart';

/// Stands in for a rewarded video until a real ad network is wired up
/// (see README §3b). It plays a countdown, then pays out — the same
/// shape as every rewarded SDK: watch to the end, earn the reward, and
/// leaving early earns nothing.
///
/// Pops `true` only when the reward was earned, so the caller can treat
/// that as "the network said it counted" and grant energy.
class RewardedAdScreen extends StatefulWidget {
  const RewardedAdScreen({super.key});

  static const Duration length = Duration(seconds: 5);

  @override
  State<RewardedAdScreen> createState() => _RewardedAdScreenState();
}

class _RewardedAdScreenState extends State<RewardedAdScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RewardedAdScreen.length,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15181C),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final finished = _controller.isCompleted;
            final secondsLeft =
                (RewardedAdScreen.length.inSeconds * (1 - _controller.value))
                    .ceil();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
                  child: Row(
                    children: [
                      const _AdLabel(),
                      const Spacer(),
                      if (finished)
                        IconButton(
                          // Closing after the countdown still pays out —
                          // the reward is earned by then.
                          onPressed: () => Navigator.of(context).pop(true),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white70),
                        )
                      else
                        _Countdown(
                          secondsLeft: secondsLeft,
                          progress: _controller.value,
                        ),
                    ],
                  ),
                ),
                const Expanded(child: Center(child: _AdPlaceholder())),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      Text(
                        finished
                            ? 'Nice! Here’s your energy.'
                            : 'Watch to the end for '
                                '+${EnergyService.adReward} energy',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: finished
                              ? () => Navigator.of(context).pop(true)
                              : null,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            finished
                                ? 'Claim +${EnergyService.adReward} ⚡'
                                : 'Please wait…',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdLabel extends StatelessWidget {
  const _AdLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'AD',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.secondsLeft, required this.progress});

  final int secondsLeft;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.white24,
            color: Colors.white,
          ),
          Text(
            '$secondsLeft',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Deliberately an empty slot rather than a mock advert — nothing here
/// should read as a real product or brand.
class _AdPlaceholder extends StatelessWidget {
  const _AdPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _AdSlotBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_outline_rounded,
                size: 64, color: Colors.white38),
            const SizedBox(height: 14),
            const Text(
              'Rewarded video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'A real ad plays here once an ad network is wired up.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdSlotBox extends StatelessWidget {
  const _AdSlotBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: child,
    );
  }
}
