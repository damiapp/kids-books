import 'package:flutter_test/flutter_test.dart';
import 'package:peekadoo/services/narration_service.dart';

/// Voice choice decides whether a child hears a natural voice or a
/// robotic one — or, for a network voice on a bad connection, nothing at
/// all, mid-word. The ranking is the part that can be checked without a
/// phone.
void main() {
  int score(String locale, {bool network = false, int? quality}) =>
      NarrationService.score({
        'name': network ? 'en-x-voice-network' : 'en-x-voice-local',
        'locale': locale,
        if (quality != null) 'quality': quality,
      });

  test('American English beats British beats any other English', () {
    expect(score('en-US'), greaterThan(score('en-GB')));
    expect(score('en-GB'), greaterThan(score('en-AU')));
  });

  test('accepts the underscore form some engines report', () {
    expect(score('en_US'), score('en-US'));
  });

  test('an offline voice beats an online one', () {
    expect(score('en-US'), greaterThan(score('en-US', network: true)));
  });

  test('offline matters more than accent', () {
    // A British voice that always works beats an American one that can
    // stall on a weak connection.
    expect(score('en-GB'), greaterThan(score('en-US', network: true)));
  });

  test('quality breaks ties but never outranks being offline', () {
    expect(score('en-US', quality: 500), greaterThan(score('en-US', quality: 300)));
    expect(score('en-US', quality: 300),
        greaterThan(score('en-US', network: true, quality: 500)));
  });

  test('a network flag in the data counts the same as one in the name', () {
    final flagged = NarrationService.score({
      'name': 'en-us-x-plain',
      'locale': 'en-US',
      'network_required': 'true',
    });
    expect(flagged, score('en-US', network: true));
  });
}
