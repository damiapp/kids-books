import 'dart:math';

import 'package:flutter/material.dart';

/// Peekadoo's motion vocabulary — the handful of movements every screen
/// shares, so the app moves in one consistent voice instead of each screen
/// inventing its own.
///
/// Every one of them checks the system "reduce motion" setting and, when
/// it's on, renders its finished state without moving. That isn't a
/// nicety for this audience: some children are genuinely unsettled by
/// motion, and their parents are the ones who turn that setting on.
bool _reduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Sinks slightly under a finger and springs back on release — the
/// "chunky button" feel that tells a small child the tap landed before
/// anything else happens.
///
/// Built on a raw pointer [Listener] rather than a gesture detector, so it
/// never competes with the InkWell or GestureDetector inside it.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.pressedScale = 0.93});

  final Widget child;
  final double pressedScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        // Quick going down, springy coming up: the press should feel
        // immediate, the release should feel alive.
        duration: Duration(milliseconds: _down ? 70 : 420),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}

/// Shakes side to side whenever [trigger] changes — the "not that one"
/// for a wrong answer. Short, damped and small on purpose: it should
/// read as "try again", never as being told off.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  /// Any change starts a shake. A counter rather than a bool, so tapping
  /// the same wrong card twice in a row shakes it twice.
  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = _reduceMotion(context);
  }

  @override
  void didUpdateWidget(covariant Shake old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger &&
        widget.trigger != 0 &&
        !_reduce) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        // Three swings, each smaller than the last.
        final dx = sin(t * pi * 6) * 9 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// Celebrates a right answer: the child bounces up and a ring of
/// sparkles bursts out of it. Plays when [active] turns true.
class Burst extends StatefulWidget {
  const Burst({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<Burst> createState() => _BurstState();
}

class _BurstState extends State<Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = _reduceMotion(context);
  }

  @override
  void didUpdateWidget(covariant Burst old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && !_reduce) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final lift = sin(pi * (t * 1.6).clamp(0.0, 1.0)) * 0.1;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.scale(scale: 1 + lift, child: child),
            if (t > 0 && t < 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _BurstPainter(t)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t);

  final double t;

  static const _colors = [
    Color(0xFFF0B429),
    Color(0xFF58A700),
    Color(0xFFE0637A),
    Color(0xFF3AA7A0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final reach = size.shortestSide;
    final eased = Curves.easeOutCubic.transform(t);
    final fade = (1 - t).clamp(0.0, 1.0);

    for (var i = 0; i < 12; i++) {
      final angle = i * 2 * pi / 12 + 0.25;
      final distance = reach * (0.32 + 0.42 * eased) * (i.isEven ? 1 : 0.82);
      final at = center + Offset(cos(angle), sin(angle)) * distance;
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: fade);
      _sparkle(canvas, at, (i.isEven ? 9 : 6) * (1 - 0.4 * t), paint);
    }
  }

  /// A four-pointed star — reads as "sparkle" at any size, and needs no
  /// font, so it can't come out as a missing-glyph box.
  void _sparkle(Canvas canvas, Offset c, double r, Paint paint) {
    final w = r * 0.32;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + w, c.dy - w, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + w, c.dy + w, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - w, c.dy + w, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - w, c.dy - w, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}

/// Grows in from small with a little overshoot, once, when it first
/// appears. Staggered [delay]s let a screen assemble itself piece by
/// piece instead of arriving all at once.
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.from = 0.6,
  });

  final Widget child;
  final Duration delay;
  final double from;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_reduceMotion(context)) {
      _controller.value = 1;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final scale =
            widget.from + (1 - widget.from) * Curves.elasticOut.transform(t);
        return Opacity(
          opacity: (t * 2.5).clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }
}

/// Floats gently up and down, forever. For the one thing on a screen
/// that's asking to be tapped.
class Bob extends StatefulWidget {
  const Bob({super.key, required this.child, this.height = 4});

  final Widget child;
  final double height;

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, sin(_controller.value * 2 * pi) * widget.height),
        child: child,
      ),
    );
  }
}

/// Confetti falling from the top of whatever it's laid over, once. Paints
/// only — it never takes a tap, so a button underneath stays usable while
/// it falls.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.pieces = 70});

  final int pieces;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );

  // Seeded, so it falls the same way every time — it's choreography, not
  // noise, and it keeps a screenshot reproducible.
  late final List<_Piece> _pieces = () {
    final rnd = Random(7);
    return [
      for (var i = 0; i < widget.pieces; i++)
        _Piece(
          x: rnd.nextDouble(),
          delay: rnd.nextDouble() * 0.35,
          fall: 0.8 + rnd.nextDouble() * 0.5,
          sway: 0.02 + rnd.nextDouble() * 0.05,
          phase: rnd.nextDouble() * 2 * pi,
          spin: (rnd.nextDouble() - 0.5) * 14,
          size: 6 + rnd.nextDouble() * 7,
          round: rnd.nextDouble() < 0.3,
          color: _BurstPainter._colors[i % _BurstPainter._colors.length],
        ),
    ];
  }();

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!_reduceMotion(context)) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_controller.value, _pieces),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.delay,
    required this.fall,
    required this.sway,
    required this.phase,
    required this.spin,
    required this.size,
    required this.round,
    required this.color,
  });

  final double x, delay, fall, sway, phase, spin, size;
  final bool round;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.pieces);

  final double t;
  final List<_Piece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local == 0) continue;
      final y = (-0.08 + local * p.fall * 1.2) * size.height;
      if (y > size.height + 20) continue;
      final x = (p.x + sin(local * 2 * pi * 1.5 + p.phase) * p.sway) *
          size.width;
      // Fade out over the last stretch rather than vanishing.
      final alpha = local > 0.8 ? (1 - local) / 0.2 : 1.0;
      final paint = Paint()..color = p.color.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(local * p.spin);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 0.5),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
