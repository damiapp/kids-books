import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sends crashes to Firebase Crashlytics, so a crash on someone else's
/// phone isn't invisible to us.
///
/// What goes out is the error, its stack trace, and the phone's model and
/// Android version — never who the child is. In particular, nothing here
/// ever calls `setUserIdentifier` or attaches the account email: a crash
/// report has no business knowing which family it came from.
///
/// On by default, with an off switch for grown-ups (GrownUpsScreen).
/// Only release builds report; a debug build's errors are already on the
/// developer's screen.
class CrashReporting {
  const CrashReporting._();

  /// The parent's choice. Shared so the switch and the reporter agree.
  static final ValueNotifier<bool> enabled = ValueNotifier(true);

  static const _enabledKey = 'crash_reports_enabled';

  /// True once Crashlytics is hooked up — release builds only.
  static bool _active = false;

  /// Call right after Firebase is initialised, before anything else can
  /// fail, so startup errors are caught too.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    enabled.value = prefs.getBool(_enabledKey) ?? true;
    if (!kReleaseMode) return;

    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(enabled.value);

    // Errors inside Flutter: a build, layout or paint that threw.
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    // Everything else on the Dart side: an async error nobody awaited.
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
    _active = true;
  }

  /// Records a harmless, labelled error, to check reports reach the
  /// Firebase console. Crashlytics uploads it on the app's next launch.
  /// False when nothing would be sent: a debug build, or switched off.
  static Future<bool> sendTest() async {
    if (!_active || !enabled.value) return false;
    await FirebaseCrashlytics.instance.recordError(
      Exception('Test report from For grown-ups'),
      StackTrace.current,
      reason: 'a test, not a crash',
    );
    return true;
  }

  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await (await SharedPreferences.getInstance()).setBool(_enabledKey, value);
    if (!_active) return;
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(value);
    // Turning it off means off: reports already waiting on the phone are
    // dropped rather than sent later.
    if (!value) await crashlytics.deleteUnsentReports();
  }
}
