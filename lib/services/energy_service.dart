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

  /// What a rewarded video is worth: exactly one lesson, so the offer is
  /// the simplest promise there is — watch a video, play a lesson.
  static const int adReward = costPerLesson;

  /// Videos per day. Five of them is a full bar, which is the point: a
  /// parent can rescue a session that ran dry, but topping up all day
  /// isn't an alternative to All Access.
  static const int maxAdsPerDay = 5;

  static const _energyKey = 'energy_current';
  static const _lastUpdateKey = 'energy_last_update_millis';
  static const _adCountKey = 'energy_ads_watched';
  static const _adDayKey = 'energy_ads_day';

  int _energy = maxEnergy;
  DateTime _lastUpdate = DateTime.now();
  int _adCount = 0;
  String _adDay = '';

  int get current => _energy;

  /// Rewarded videos watched today. The count is stamped with the day it
  /// belongs to, so a new day reads as zero without needing a timer or a
  /// midnight cleanup pass.
  int get adsWatchedToday => _adDay == _today ? _adCount : 0;

  int get adsLeftToday => maxAdsPerDay - adsWatchedToday;

  /// Whether to offer a video at all. Not when the bar is already full —
  /// the reward would evaporate against the cap.
  bool get canWatchAd => _energy < maxEnergy && adsLeftToday > 0;

  /// Local calendar day. A plain date string rather than arithmetic on
  /// timestamps, so the reset lands at local midnight and DST doesn't
  /// shift it.
  static String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

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
    _adCount = prefs.getInt(_adCountKey) ?? 0;
    _adDay = prefs.getString(_adDayKey) ?? '';
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

  /// Pays out a watched rewarded video. Returns false if the offer had
  /// already lapsed — the day's videos are used up, or the bar filled up
  /// while the video was playing.
  Future<bool> grantAdReward() async {
    if (!canWatchAd) return false;
    _adCount = adsWatchedToday + 1;
    _adDay = _today;
    _energy = (_energy + adReward).clamp(0, maxEnergy).toInt();
    await _persist();
    notifyListeners();
    return true;
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
    await prefs.setInt(_adCountKey, _adCount);
    await prefs.setString(_adDayKey, _adDay);
  }
}
