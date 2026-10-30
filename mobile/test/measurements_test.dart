import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:entrenaya_mobile/core/app_theme.dart';
import 'package:entrenaya_mobile/features/measurements/measurement.dart';
import 'package:entrenaya_mobile/features/measurements/measurements_screen.dart';

import 'workout_test.dart' show MemoryPreferences;

void main() {
  test(
    'partial measurements compare chronologically and survive storage',
    () async {
      SharedPreferencesAsyncPlatform.instance = MemoryPreferences();
      final repository = MeasurementRepository();
      await repository.save([
        MeasurementEntry(
          id: 'new',
          date: DateTime(2026, 10, 30),
          values: {BodyMeasure.waist: 86.5},
        ),
        MeasurementEntry(
          id: 'partial',
          date: DateTime(2026, 10, 25),
          values: {BodyMeasure.leftArm: 35},
        ),
        MeasurementEntry(
          id: 'old',
          date: DateTime(2026, 10, 20),
          values: {BodyMeasure.waist: 90, BodyMeasure.leftArm: 34},
        ),
      ]);
      final loaded = await repository.load();
      final waist = measurementsFor(loaded, BodyMeasure.waist);
      expect(waist.map((e) => e.id), ['old', 'new']);
      expect(
        waist.last.values[BodyMeasure.waist]! -
            waist.first.values[BodyMeasure.waist]!,
        -3.5,
      );
      expect(measurementsFor(loaded, BodyMeasure.back), isEmpty);
      expect(measureNumber(86.5), '86,5');
    },
  );

  testWidgets('saves measurements, shows change and reloads history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = MemoryPreferences();
    SharedPreferencesAsyncPlatform.instance = storage;
    await MeasurementRepository().save([
      MeasurementEntry(
        id: 'previous',
        date: DateTime.now().subtract(const Duration(days: 10)),
        values: {BodyMeasure.waist: 90},
      ),
    ]);
    Widget app() =>
        MaterialApp(theme: AppTheme.dark, home: const MeasurementsScreen());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar medidas'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('measure_waist')), '86,5');
    await tester.ensureVisible(find.text('Guardar medidas'));
    await tester.tap(find.text('Guardar medidas'));
    await tester.pumpAndSettle();
    expect(find.text('86,5 cm'), findsWidgets);
    expect(find.text('-3,5 cm desde el primer registro'), findsOneWidget);
    expect(
      jsonDecode(storage.values[MeasurementRepository.storageKey]!),
      hasLength(2),
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('-3,5 cm desde el primer registro'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byTooltip('Editar registro').first,
      200,
    );
    await tester.tap(find.byTooltip('Editar registro').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('measure_waist')), '85');
    await tester.ensureVisible(find.text('Guardar medidas'));
    await tester.tap(find.text('Guardar medidas'));
    await tester.pumpAndSettle();
    expect(
      jsonDecode(storage.values[MeasurementRepository.storageKey]!),
      hasLength(2),
    );
    final latest = (await MeasurementRepository().load()).last;
    expect(latest.values[BodyMeasure.waist], 85);
      await tester.scrollUntilVisible(find.byTooltip('Eliminar registro').first, 200);
      await tester.tap(find.byTooltip('Eliminar registro').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      final remaining = await MeasurementRepository().load();
      expect(remaining, hasLength(1));
      expect(remaining.single.values[BodyMeasure.waist], 90);
    await tester.pumpWidget(const SizedBox());
  });
}
