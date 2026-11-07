import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scm/main.dart';

void main() {
  testWidgets('71 International Import Engine Auth & Smoke Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: AntigravityScmApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial route renders Auth Screen
    expect(find.text('71 INTERNATIONAL'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    expect(find.text('Zero-OTP Sign Up'), findsOneWidget);

    // Tap Sign In to log into the application
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    // Verify redirected to Onboarding Wizard
    expect(find.text('71 INTERNATIONAL // SETUP WIZARD'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Workspace & Base Currency'), findsOneWidget);

    // Advance to Step 2
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Default Sourcing Origin Currency'), findsOneWidget);

    // Advance to Step 3
    final continueBtn2 = find.text('Continue');
    await tester.ensureVisible(continueBtn2);
    await tester.tap(continueBtn2);
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Operational Workflow Preset'), findsOneWidget);

    // Complete Onboarding and enter Command Center
    final launchBtn = find.text('Launch Command Center');
    await tester.ensureVisible(launchBtn);
    await tester.tap(launchBtn);
    await tester.pumpAndSettle();

    // Verify Command Center loaded
    expect(find.text('71 INTERNATIONAL // COMMAND ENGINE'), findsOneWidget);
    expect(find.text('Owner Executive'), findsOneWidget);
  });
}
