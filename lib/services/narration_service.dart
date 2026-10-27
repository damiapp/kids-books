import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How fast the voice talks — chosen by a grown-up, since the right pace
/// for a just-turned-three is wrong for a six-year-old.
enum SpeechSpeed {
  slower('Slower', 0.34),
  normal('Normal', 0.42),
  faster('Faster', 0.5);

  const SpeechSpeed(this.label, this.rate);

  final String label;

  /// flutter_tts's scale, where 0.5 is the engine's own normal pace.
  /// "Normal" here is a little under it on purpose: easier for early
  /// learners.
  final double rate;
}

/// Reads words, sentences and instructions aloud through the phone's own
/// text-to-speech engine. Offline — no account, no network call, no key.
///
/// Since the app was taught to speak everything a child can't read, this
/// is no longer a nicety: if it falls silent, a three-year-old can't use
/// the app at all. So it doesn't just take whatever the phone defaults
/// to. Once per run it picks the best English voice actually installed,
/// and when there's none, it says so ([englishVoice]) instead of failing
/// quietly.
class NarrationService extends ChangeNotifier {
  NarrationService() {
    _tts
      ..setSpeechRate(speed.value.rate)
      ..setPitch(1.05)
      ..setStartHandler(() => _setSpeaking(true))
      ..setCompletionHandler(() => _setSpeaking(false))
      ..setCancelHandler(() => _setSpeaking(false))
      ..setErrorHandler((_) => _setSpeaking(false));
    _ready = _setup ??= _chooseVoice(_tts);
  }

  final FlutterTts _tts = FlutterTts();
  late final Future<bool> _ready;
  bool _speaking = false;

  /// Shared by every instance. The speech engine is one native object no
  /// matter how many of these exist, choosing a voice takes a few hundred
  /// milliseconds, and the answer can't change while the app runs.
  static Future<bool>? _setup;

  /// Forgets the chosen voice. Tests need it: a Future remembers the zone
  /// it was made in, and each widget test runs in its own fake clock, so
  /// a setup cached by one test would answer only that test's clock.
  @visibleForTesting
  static void resetForTest() => _setup = null;

  /// Whether this phone can speak English at all — null until checked.
  /// False means the app will be silent, which for this audience means
  /// unusable, so the map shows a parent how to fix it.
  static final ValueNotifier<bool?> englishVoice = ValueNotifier(null);

  /// Shared by every instance, so a change in the grown-ups screen
  /// applies to the very next word spoken anywhere.
  static final ValueNotifier<SpeechSpeed> speed =
      ValueNotifier(SpeechSpeed.normal);

  static const _speedKey = 'narration_speed';

  /// Reads the saved speed. Called once at startup, before anything
  /// speaks.
  static Future<void> loadSettings() async {
    final saved = (await SharedPreferences.getInstance()).getString(_speedKey);
    speed.value = SpeechSpeed.values.firstWhere(
      (s) => s.name == saved,
      orElse: () => SpeechSpeed.normal,
    );
  }

  static Future<void> setSpeed(SpeechSpeed value) async {
    speed.value = value;
    await (await SharedPreferences.getInstance())
        .setString(_speedKey, value.name);
  }

  bool get isSpeaking => _speaking;

  void _setSpeaking(bool value) {
    if (_speaking == value) return;
    _speaking = value;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    await _ready;
    await _tts.stop();
    await _tts.setSpeechRate(speed.value.rate);
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // ── Choosing a voice ────────────────────────────────────────────────

  /// Google's engine sounds the same on every phone that has it, and has
  /// the most natural English voices. Samsung, Xiaomi and others ship
  /// their own as the default, and those vary widely.
  static const _googleEngine = 'com.google.android.tts';

  static Future<bool> _chooseVoice(FlutterTts tts) async {
    var available = true;
    try {
      final engines = _strings(await tts.getEngines);
      if (engines.contains(_googleEngine)) {
        await tts.setEngine(_googleEngine);
      }
      await tts.setLanguage('en-US');

      final english = [
        for (final voice in _maps(await tts.getVoices))
          if (_text(voice['locale']).toLowerCase().startsWith('en')) voice,
      ];

      if (english.isEmpty) {
        // Some engines don't list their voices; ask directly instead.
        available = await tts.isLanguageAvailable('en-US') == true ||
            await tts.isLanguageAvailable('en-GB') == true;
      } else {
        english.sort((a, b) => _score(b).compareTo(_score(a)));
        final best = english.first;
        await tts.setVoice({
          'name': _text(best['name']),
          'locale': _text(best['locale']),
        });
      }
    } catch (error) {
      // Best effort. A phone that won't describe its voices can usually
      // still speak with its default one, so this isn't "no voice".
      debugPrint('Voice selection skipped: $error');
    }
    englishVoice.value = available;
    return available;
  }

  /// Higher is better. Locale first (the catalog is American English),
  /// then offline over online — a network voice stalls or goes silent on
  /// a bad connection, mid-word — then the engine's own quality rating.
  @visibleForTesting
  static int score(Map<String, Object?> voice) => _score(voice);

  static int _score(Map<String, Object?> voice) {
    final locale = _text(voice['locale']).toLowerCase().replaceAll('_', '-');
    final name = _text(voice['name']).toLowerCase();

    var score = locale == 'en-us'
        ? 30
        : locale.startsWith('en-gb')
            ? 20
            : 10;

    final online = _text(voice['network_required']) == 'true' ||
        name.contains('network');
    if (!online) score += 25;

    // Android rates voices 100–500; very high is worth an accent step,
    // never an offline one.
    final quality = int.tryParse(_text(voice['quality']));
    if (quality != null) score += (quality ~/ 50).clamp(0, 10).toInt();

    return score;
  }

  static String _text(Object? value) => value?.toString() ?? '';

  static List<String> _strings(Object? value) =>
      value is List ? [for (final v in value) v.toString()] : const [];

  static List<Map<String, Object?>> _maps(Object? value) => value is List
      ? [
          for (final v in value)
            if (v is Map) {for (final e in v.entries) e.key.toString(): e.value},
        ]
      : const [];
}
