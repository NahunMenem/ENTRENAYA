import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:entrenaya_mobile/core/app_theme.dart';
import 'package:entrenaya_mobile/core/models.dart';
import 'package:entrenaya_mobile/features/home/simple_home.dart';
import 'package:entrenaya_mobile/features/routines/routine.dart';
import 'package:entrenaya_mobile/features/routines/routine_editor.dart';
import 'package:entrenaya_mobile/features/routines/published_routines.dart';
import 'package:entrenaya_mobile/features/routines/teacher_routines.dart';
import 'package:entrenaya_mobile/features/training/workout_screen.dart';
import 'workout_test.dart' show MemoryPreferences;

void main() {
  const profile = AthleteProfile(
    name: 'Ana',
    goal: 'Fuerza',
    level: 'Principiante',
    trainingPlace: 'Gimnasio',
    daysPerWeek: 3,
    sessionMinutes: 45,
  );
  for (final action in [
    'Crear mi rutina',
    'Elegir una rutina',
    'Rutina de mi profe',
  ]) {
    testWidgets('home opens $action directly', (tester) async {
      SharedPreferencesAsyncPlatform.instance = MemoryPreferences();
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SimpleHome(
              profile: profile,
              onSavedRoutines: () {},
              onProgress: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(action));
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
      expect(
        find.byType(
          action == 'Crear mi rutina'
              ? RoutineEditor
              : action == 'Elegir una rutina'
              ? PublishedRoutines
              : TeacherRoutines,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('teacher routine can be received, persisted and started', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance = MemoryPreferences();
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const code = '00000000-0000-0000-0000-000000000001';
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/routines/$code');
      return http.Response(
        jsonEncode({
          'id': code,
          'name': 'Rutina del gimnasio',
          'days': [1, 3],
          'exercises': [
            {
              'id': 'sentadilla',
              'name': 'Sentadilla',
              'sets': 2,
              'reps': 10,
              'rest_seconds': 60,
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: TeacherRoutines(client: client),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), code);
    await tester.enterText(find.byType(TextField).at(1), 'Lucas');
    await tester.ensureVisible(find.text('Agregar rutina del profe'));
    await tester.tap(find.text('Agregar rutina del profe'));
    await tester.pumpAndSettle();
    final saved = (await RoutineRepository().load()).single;
    expect(saved.source, 'teacher');
    expect(saved.assignedBy, 'Lucas');
    expect(saved.exercises.single.sets, 2);
    await tester.ensureVisible(find.text('Hacer esta rutina'));
    await tester.tap(find.text('Hacer esta rutina'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
    expect(find.text('Rutina del gimnasio'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    client.close();
  });
}
