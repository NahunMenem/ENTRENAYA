import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:entrenaya_mobile/core/app_theme.dart';
import 'package:entrenaya_mobile/features/training/exercise_cover.dart';

void main() {
  testWidgets('cover only offers playback when a video exists', (tester) async {
    Widget app(String? url) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: ExerciseCover(name: 'Press', videoUrl: url),
      ),
    );
    await tester.pumpWidget(app(null));
    expect(find.byTooltip('Ver video del ejercicio'), findsNothing);
    expect(find.text('Video próximamente'), findsOneWidget);
    await tester.pumpWidget(app('https://example.com/press.mp4'));
    expect(find.byTooltip('Ver video del ejercicio'), findsOneWidget);
    expect(find.text('Video próximamente'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
