import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peekadoo/screens/grown_ups_screen.dart';
import 'package:peekadoo/services/energy_service.dart';
import 'package:peekadoo/services/entitlement_service.dart';
import 'package:peekadoo/services/narration_service.dart';
import 'package:peekadoo/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> spoken;
  late List<double> rates;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NarrationService.resetForTest();
    NarrationService.speed.value = SpeechSpeed.normal;
    spoken = [];
    rates = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'),
            (call) async {
      if (call.method == 'speak') spoken.add(call.arguments as String);
      if (call.method == 'setSpeechRate') {
        rates.add((call.arguments as num).toDouble());
      }
      return 1;
    });
  });

  testWidgets('choosing a voice speed plays a sample at that speed and '
      'is remembered', (tester) async {
    final progress = ProgressService();
    await progress.init();
    final energy = EnergyService();
    await energy.init();

    await tester.pumpWidget(MaterialApp(
      home: GrownUpsScreen(
        progress: progress,
        energy: energy,
        entitlements: DemoEntitlementService(),
      ),
    ));

    await tester.tap(find.text('Slower'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(NarrationService.speed.value, SpeechSpeed.slower);
    expect(spoken.last, 'Can you find... apple?');
    expect(rates.last, SpeechSpeed.slower.rate);

    // As the app would at its next launch.
    NarrationService.speed.value = SpeechSpeed.normal;
    await NarrationService.loadSettings();
    expect(NarrationService.speed.value, SpeechSpeed.slower);
  });

  testWidgets('without an account, there are no account controls',
      (tester) async {
    final progress = ProgressService();
    await progress.init();
    final energy = EnergyService();
    await energy.init();

    await tester.pumpWidget(MaterialApp(
      home: GrownUpsScreen(
        progress: progress,
        energy: energy,
        entitlements: DemoEntitlementService(),
      ),
    ));

    expect(find.text('Sign out'), findsNothing);
    expect(find.text('Delete account'), findsNothing);
  });
}
