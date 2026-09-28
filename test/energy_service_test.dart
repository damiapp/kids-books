import 'package:flutter_test/flutter_test.dart';
import 'package:peekadoo/services/energy_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Energy regenerates in ten-minute steps, so without a movable clock
/// these would have to sit and wait for one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 5, 10, 9);
    EnergyService.clock = () => now;
  });

  tearDown(() => EnergyService.clock = DateTime.now);

  Future<EnergyService> fresh() async {
    final energy = EnergyService();
    await energy.init();
    return energy;
  }

  test('starts full', () async {
    expect((await fresh()).current, EnergyService.maxEnergy);
  });

  test('spending takes the cost', () async {
    final energy = await fresh();
    expect(await energy.spend(EnergyService.costPerLesson), isTrue);
    expect(energy.current, EnergyService.maxEnergy - EnergyService.costPerLesson);
  });

  test('refuses to spend what is not there, and takes nothing', () async {
    final energy = await fresh();
    for (var i = 0; i < 5; i++) {
      await energy.spend(EnergyService.costPerLesson);
    }
    expect(energy.current, 0);
    expect(await energy.spend(EnergyService.costPerLesson), isFalse);
    expect(energy.current, 0, reason: 'a refused spend must not go negative');
  });

  test('regenerates one point per interval', () async {
    final energy = await fresh();
    await energy.spend(10);
    final after = energy.current;

    now = now.add(EnergyService.regenInterval);
    await energy.refresh();
    expect(energy.current, after + 1);

    now = now.add(EnergyService.regenInterval * 3);
    await energy.refresh();
    expect(energy.current, after + 4);
  });

  test('does not regenerate before an interval is up', () async {
    final energy = await fresh();
    await energy.spend(10);
    final after = energy.current;
    now = now.add(EnergyService.regenInterval - const Duration(minutes: 1));
    await energy.refresh();
    expect(energy.current, after);
  });

  test('never regenerates past the cap', () async {
    final energy = await fresh();
    await energy.spend(5);
    now = now.add(EnergyService.regenInterval * 500);
    await energy.refresh();
    expect(energy.current, EnergyService.maxEnergy);
  });

  test('keeps the part-interval, so time is not thrown away', () async {
    final energy = await fresh();
    await energy.spend(10);
    final after = energy.current;

    // Nine tenths of the way to a point...
    now = now.add(EnergyService.regenInterval * 0.9);
    await energy.refresh();
    expect(energy.current, after);

    // ...so a fifth more should finish it, not restart the wait.
    now = now.add(EnergyService.regenInterval * 0.2);
    await energy.refresh();
    expect(energy.current, after + 1);
  });

  test('counts time spent with the app closed', () async {
    final first = await fresh();
    await first.spend(10);
    final after = first.current;

    now = now.add(EnergyService.regenInterval * 2);
    final second = await fresh();
    expect(second.current, after + 2);
  });

  test('timeUntilNext is null only when full', () async {
    final energy = await fresh();
    expect(energy.timeUntilNext, isNull);
    await energy.spend(5);
    expect(energy.timeUntilNext, isNotNull);
    expect(energy.timeUntilNext!.inMinutes,
        lessThanOrEqualTo(EnergyService.regenInterval.inMinutes));
  });

  test('canAfford matches what spend will do', () async {
    final energy = await fresh();
    await energy.spend(EnergyService.maxEnergy - 2);
    expect(energy.canAfford(EnergyService.costPerLesson), isFalse);
    expect(await energy.spend(EnergyService.costPerLesson), isFalse);
  });
}
