import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peekadoo/models/lesson.dart';

/// This file exists mainly to occupy the name.
///
/// CI regenerates the project with `flutter create` on every build, and
/// that template writes its own `test/widget_test.dart` which pumps a
/// `MyApp` this app doesn't have — a test failure on a green codebase.
/// `flutter create` skips files that already exist, so keeping a real
/// one here is what stops it.
///
/// The app itself can't be pumped in a unit test anyway: `main()`
/// initialises Firebase first, which needs a platform that isn't there.
/// Widget coverage would need those services injected.
void main() {
  group('colorFromHex', () {
    test('reads the catalog format', () {
      expect(colorFromHex('#3AA7A0'), const Color(0xFF3AA7A0));
    });

    test('is opaque even though the file never says so', () {
      // Every catalog colour is a flat card background. A value that
      // parsed as transparent would render as an invisible card rather
      // than an error, so the alpha byte is forced rather than parsed.
      expect(colorFromHex('#000000'), const Color(0xFF000000));
    });

    test('tolerates a missing hash', () {
      expect(colorFromHex('3AA7A0'), colorFromHex('#3AA7A0'));
    });
  });
}
