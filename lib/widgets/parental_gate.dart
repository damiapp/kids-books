import 'dart:math';

import 'package:flutter/material.dart';

/// "Ask a grown-up" — stands in front of anything about money or the
/// account, so a child can't reach a payment screen by tapping around.
///
/// The challenge is a two-digit number spelled out in words ("forty-two")
/// that has to be typed back as digits. Reading it is the gate. Unlike
/// multiple choice there's nothing to get right by tapping at random, and
/// unlike a sum it doesn't feel like a test to an adult in a hurry.
///
/// Deliberately silent: everything else in the app is spoken for a child
/// who can't read, and this is the one place that isn't, on purpose.
class ParentalGate {
  const ParentalGate._();

  /// True only if the challenge was answered. Dismissing it is a no.
  static Future<bool> show(BuildContext context) async {
    final passed = await showDialog<bool>(
      context: context,
      builder: (_) => const _GateDialog(),
    );
    return passed ?? false;
  }
}

class _GateDialog extends StatefulWidget {
  const _GateDialog();

  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> {
  // Two digits, never a round ten — "forty" alone would be one key press
  // away from a lucky guess.
  late final int _target = () {
    final rnd = Random();
    int n;
    do {
      n = 21 + rnd.nextInt(79);
    } while (n % 10 == 0);
    return n;
  }();

  String _typed = '';
  bool _wrong = false;

  void _press(String digit) {
    if (_typed.length >= 2) return;
    setState(() {
      _typed += digit;
      _wrong = false;
    });
    if (_typed.length == 2) {
      if (_typed == '$_target') {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _wrong = true;
          _typed = '';
        });
      }
    }
  }

  void _backspace() {
    if (_typed.isEmpty) return;
    setState(() => _typed = _typed.substring(0, _typed.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('For grown-ups'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Type this number to continue:',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            _spell(_target),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          Container(
            width: 110,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _wrong ? scheme.error : Colors.transparent,
                width: 2,
              ),
            ),
            child: Text(
              _typed,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
              ),
            ),
          ),
          if (_wrong) ...[
            const SizedBox(height: 8),
            Text('Not quite — try again.',
                style: TextStyle(color: scheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final d in const [
                '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
              ])
                _Key(onTap: () => _press(d), child: Text(d)),
              _Key(
                onTap: _backspace,
                child: const Icon(Icons.backspace_outlined, size: 18),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          textStyle:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: child,
      ),
    );
  }
}

const _ones = [
  '', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
];
const _tens = [
  '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy',
  'eighty', 'ninety',
];

/// Only ever asked for 21–99 with a non-zero unit, so no teens to spell.
String _spell(int n) => '${_tens[n ~/ 10]}-${_ones[n % 10]}';
