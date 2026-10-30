import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:entrenaya_mobile/main.dart';
import 'package:entrenaya_mobile/features/home/home_shell.dart';

void main() {
  for (final label in [
    'Comenzar',
    'Continuar con Google',
    '¿Ya tenés cuenta?  Iniciá sesión',
  ]) {
    testWidgets('$label opens the preview without authentication', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 790);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const EntrenaYaApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.textContaining('Falta configurar'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
