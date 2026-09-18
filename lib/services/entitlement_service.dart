import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The single source of truth for "is this an All Access (premium) user?".
/// The UI never talks to a billing SDK directly — it only asks this.
///
/// Premium subscribers get unlimited energy (see EnergyService); everyone
/// else spends energy per lesson.
abstract class EntitlementService extends ChangeNotifier {
  /// True while an all-access subscription is active.
  bool get subscriptionActive;

  Future<void> init();

  /// Start the all-access subscription. Returns true if now active.
  Future<bool> subscribe();

  /// Restore past purchases — required to be available on both stores.
  Future<void> restore();
}

/// Runs with zero store setup so you can click the entire flow today.
/// Persists locally. NOT real money.
class DemoEntitlementService extends EntitlementService {
  static const _subKey = 'demo_subscription_active';

  bool _sub = false;

  @override
  bool get subscriptionActive => _sub;

  @override
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _sub = prefs.getBool(_subKey) ?? false;
    notifyListeners();
  }

  @override
  Future<bool> subscribe() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _sub = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subKey, true);
    notifyListeners();
    return true;
  }

  @override
  Future<void> restore() => init();

  /// Overwrites local state to match a built-in demo account (see
  /// AuthService / DemoAccount) — used only by the mock sign-in flow.
  Future<void> applyDemoPreset({required bool subscriptionActive}) async {
    _sub = subscriptionActive;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subKey, _sub);
    notifyListeners();
  }
}
