import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:job_management/demo/demo_app.dart';
import 'package:job_management/demo/demo_store.dart';

void main() {
  testWidgets('Register, sign in and explore every demo section',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = await DemoStore.load();
    await tester.pumpWidget(DemoApp(store: store));
    await tester.ensureVisible(find.text('New here? Create an account'));
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Test Candidate');
    await tester.enterText(
        find.byType(TextField).at(1), 'candidate@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'Test123!');
    await tester.ensureVisible(find.text('Register'));
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), 'Test123!');
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Junior Flutter Developer'), findsOneWidget);
    await tester.tap(find.byTooltip('Save job').first);
    await tester.pumpAndSettle();
    expect(store.values('saved'), contains('flutter'));
    await tester.tap(find.text('View & apply').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(store.values('applied'), contains('flutter'));
    for (final label in ['Learning', 'Companies', 'Calendar', 'Profile']) {
      await tester.tap(find.widgetWithText(NavigationDestination, label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$label should render');
    }
    expect(find.text('Test Candidate'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(DemoHome))).clearSnackBars();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
