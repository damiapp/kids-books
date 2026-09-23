import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Duolingo-style energy pool that gates starting a lesson. Free users have
/// a capped pool that slowly refills over time; premium (subscribed) users
/// bypass it entirely — see EntitlementService.subscriptionActive.
///
/// Local only, like the other demo-mode services — swap for a
/// server-tracked pool if you ever want energy to be shared across devices.
class EnergyService extends ChangeNotifier {
  static const int maxEnergy = 25;
  static const int costPerLesson = 5;
  static const Duration regenInterval = Duration(minutes: 10);

  static const _energyKey = 'energy_current';
  static const _lastUpdateKey = 'energy_last_update_millis';

  int _energy = maxEnergy;
  DateTime _lastUpdate = DateTime.now();

  int get current => _energy;

  /// Null once full; otherwise how long until the next point regenerates.
  Duration? get timeUntilNext {
    if (_energy >= maxEnergy) return null;
    final elapsed = DateTime.now().difference(_lastUpdate);
    final remainder = regenInterval - elapsed;
    return remainder.isNegative ? Duration.zero : remainder;
  }

  bool canAfford(int cost) => _energy >= cost;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _energy = prefs.getInt(_energyKey) ?? maxEnergy;
    final lastMillis = prefs.getInt(_lastUpdateKey);
    _lastUpdate = lastMillis == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(lastMillis);
    await _regenerate();
  }

  /// Re-applies any regen owed since the last check — call when a screen
  /// that shows the energy bar becomes visible, since there's no
  /// background timer ticking it forward on its own.
  Future<void> refresh() => _regenerate();

  Future<void> _regenerate() async {
    if (_energy >= maxEnergy) {
      _lastUpdate = DateTime.now();
      return;
    }
    final elapsed = DateTime.now().difference(_lastUpdate);
    final ticks = elapsed.inMilliseconds ~/ regenInterval.inMilliseconds;
    if (ticks <= 0) return;
    _energy = (_energy + ticks).clamp(0, maxEnergy).toInt();
    _lastUpdate = _lastUpdate.add(regenInterval * ticks);
    await _persist();
    notifyListeners();
  }

  /// Spends [cost] energy if there's enough. Returns true if it succeeded.
  Future<bool> spend(int cost) async {
    await _regenerate();
    if (_energy < cost) return false;
    _energy -= cost;
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_energyKey, _energy);
    await prefs.setInt(
        _lastUpdateKey, _lastUpdate.millisecondsSinceEpoch);
  }
}
