import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import 'package:entrenaya_mobile/core/app_theme.dart';
import 'package:entrenaya_mobile/features/training/workout_screen.dart';

final class MemoryPreferences extends SharedPreferencesAsyncPlatform {
  final values = <String, String>{};
  @override
  Future<String?> getString(
    String key,
    SharedPreferencesOptions options,
  ) async => values[key];
  @override
  Future<void> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'records each set, skips only rest, restores draft and shows previous session',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final storage = MemoryPreferences();
      SharedPreferencesAsyncPlatform.instance = storage;
      Widget app() =>
          MaterialApp(theme: AppTheme.dark, home: const WorkoutScreen());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Serie actual'), findsOneWidget);
      final emptyWeight = tester.widget<TextField>(
        find.byKey(const ValueKey('0_0_kg')),
      );
      expect(emptyWeight.controller!.text, isEmpty);
      expect(emptyWeight.decoration!.hintText, 'Ingresá peso');
      final emptyReps = tester.widget<TextField>(
        find.byKey(const ValueKey('0_0_reps')),
      );
      expect(emptyReps.controller!.text, isEmpty);
      expect(emptyReps.decoration!.hintText, 'Ingresá reps');
      await tester.enterText(find.byKey(const ValueKey('0_0_kg')), '42,5');
      await tester.enterText(find.byKey(const ValueKey('0_0_reps')), '10');
      await tester.ensureVisible(
        find.text('Guardar serie 1 e iniciar descanso'),
      );
      await tester.tap(find.text('Guardar serie 1 e iniciar descanso'));
      await tester.pumpAndSettle();
      expect(find.text('Descansando…'), findsOneWidget);
      expect(find.text('Guardada'), findsOneWidget);
      await tester.ensureVisible(find.text('Omitir descanso'));
      await tester.tap(find.text('Omitir descanso'));
      await tester.pumpAndSettle();
      var saved =
          jsonDecode(storage.values['entrenaya.workouts.v1']!)
              as Map<String, dynamic>;
      final sets = saved['draft']['exercises']['press-banca'] as List<dynamic>;
      expect(sets[0]['weight'], '42,5');
      expect(sets[0]['reps'], '10');
      expect(sets[0]['completed'], true);
      expect(sets[1]['completed'], false);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('0_0_kg')),
      );
      expect(field.controller!.text, '42,5');
      expect(find.textContaining('SERIE 2 DE 4'), findsOneWidget);
      await tester.tap(find.text('Finalizar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar y finalizar'));
      await tester.pumpAndSettle();
      saved =
          jsonDecode(storage.values['entrenaya.workouts.v1']!)
              as Map<String, dynamic>;
      expect(saved['draft'], isNull);
      expect(saved['history'], hasLength(1));

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Sesión anterior: 42,5 kg × 10'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
