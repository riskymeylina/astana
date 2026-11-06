import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('onboarding adapts to common screen sizes and opens login', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const sizes = [
      Size(320, 568),
      Size(768, 1024),
      Size(900, 600),
      Size(1440, 900),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: const OnboardingScreen(),
          routes: {'/login': (_) => const Scaffold(body: Text('LOGIN TARGET'))},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mulai Menjelajahi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.tap(find.text('Mulai Menjelajahi'));
    await tester.pumpAndSettle();
    expect(find.text('LOGIN TARGET'), findsOneWidget);
  });
}
