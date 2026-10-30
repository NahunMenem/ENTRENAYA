import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:entrenaya_mobile/core/app_theme.dart';
import 'package:entrenaya_mobile/features/routines/routine.dart';
import 'package:entrenaya_mobile/features/routines/routines_screen.dart';
import 'package:entrenaya_mobile/features/training/workout_screen.dart';
import 'workout_test.dart' show MemoryPreferences;

void main() {
  testWidgets('creates a named weekly routine from the library and starts it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferencesAsyncPlatform.instance = MemoryPreferences();
    Widget app() => MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(body: RoutinesScreen()),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear mi rutina'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('routine_name')),
      'Piernas de la semana',
    );
    await tester.tap(find.text('Lun'));
    await tester.tap(find.text('Jue'));
    await tester.ensureVisible(find.text('Agregar ejercicio'));
    await tester.tap(find.text('Agregar ejercicio'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'sentadilla');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sentadilla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar rutina'));
    await tester.pumpAndSettle();
    final saved = (await RoutineRepository().load()).single;
    expect(saved.name, 'Piernas de la semana');
    expect(saved.days, [1, 4]);
    expect(saved.exercises.single.id, 'sentadilla');
    expect(saved.exercises.single.sets, 3);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Piernas de la semana'), findsOneWidget);
    await tester.tap(find.text('Mar'));
    await tester.pumpAndSettle();
    expect(find.text('Piernas de la semana'), findsNothing);
    await tester.tap(find.text('Lun'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Entrenar esta rutina'));
    await tester.tap(find.text('Entrenar esta rutina'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
    expect(find.textContaining('EJERCICIO 1 DE 1'), findsOneWidget);
    expect(find.textContaining('SERIE 1 DE 3'), findsOneWidget);
    expect(find.text('Sentadilla'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('custom workout respects its set count, targets and rest', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferencesAsyncPlatform.instance = MemoryPreferences();
    const routine = TrainingRoutine(
      id: 'test',
      name: 'Mi fuerza',
      days: [1],
      exercises: [
        RoutineExercise(
          id: 'sentadilla',
          name: 'Sentadilla',
          sets: 1,
          reps: 8,
          restSeconds: 0,
        ),
        RoutineExercise(
          id: 'press-banca',
          name: 'Press de banca',
          sets: 2,
          reps: 10,
          restSeconds: 60,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const WorkoutScreen(routine: routine),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Objetivo: 8 repeticiones'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('0_0_kg')));
    await tester.enterText(find.byKey(const ValueKey('0_0_kg')), '40');
    await tester.enterText(find.byKey(const ValueKey('0_0_reps')), '8');
    await tester.tap(find.text('Guardar serie 1'));
    await tester.pumpAndSettle();
    expect(find.text('Ejercicio completado'), findsOneWidget);
    expect(find.text('Descansando…'), findsNothing);
    await tester.tap(find.text('Siguiente ejercicio →'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SERIE 1 DE 2'), findsOneWidget);
    expect(find.textContaining('Objetivo: 10 repeticiones'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
