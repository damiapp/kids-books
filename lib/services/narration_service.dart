import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reads page text aloud via the device's built-in text-to-speech engine.
/// Works fully offline — no account, no network call, no API key.
class NarrationService extends ChangeNotifier {
  NarrationService() {
    _tts
      ..setLanguage('en-US')
      ..setSpeechRate(0.42) // slower than default: easier for early readers
      ..setPitch(1.05)
      ..setStartHandler(() => _setSpeaking(true))
      ..setCompletionHandler(() => _setSpeaking(false))
      ..setCancelHandler(() => _setSpeaking(false))
      ..setErrorHandler((_) => _setSpeaking(false));
  }

  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  bool get isSpeaking => _speaking;

  void _setSpeaking(bool value) {
    if (_speaking == value) return;
    _speaking = value;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
