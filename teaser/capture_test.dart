// Run explicitly: flutter test teaser/capture_test.dart
// Captures the actual app through Flutter's renderer, with isolated demo state.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:job_management/demo/demo_app.dart';
import 'package:job_management/demo/demo_store.dart';

void main() {
  testWidgets('Capture the real offline demo candidate journey', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final root = GlobalKey();
    final output = Directory('teaser/captures')..createSync(recursive: true);
    // Tests normally use Ahem. Load Flutter's actual Roboto UI fonts.
    for (final family in ['Ahem', 'Roboto']) {
      final loader = FontLoader(family);
      for (final file in ['roboto-regular.ttf', 'roboto-bold.ttf']) {
        loader.addFont(Future.value(ByteData.sublistView(
          File('D:/Flutter/flutter/bin/cache/artifacts/material_fonts/$file').readAsBytesSync())));
      }
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(
      File('D:/Flutter/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf').readAsBytesSync())));
    await icons.load();
    SharedPreferences.setMockInitialValues({});
    final store = await DemoStore.load();
    await tester.pumpWidget(RepaintBoundary(key: root, child: DemoApp(store: store)));
    await tester.runAsync(() async {
      await precacheImage(const AssetImage('assets/logo-talentlink.png'), root.currentContext!);
    });
    await tester.pumpAndSettle();
    var serial = 0;
    var clock = 0.0;
    final frames = <Map<String, dynamic>>[];
    final taps = <Map<String, dynamic>>[];
    final scenes = <Map<String, dynamic>>[];
    String shot = '';
    double start = 0;

    Future<void> capture(double duration) async {
      final file = '${(serial++).toString().padLeft(4, '0')}.png';
      await tester.runAsync(() async {
        final boundary = root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${output.path}/$file').writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      frames.add({'file': file, 'start': clock, 'duration': duration, 'shot': shot});
      clock += duration;
    }
    Future<void> animate(double duration) async {
      final count = (duration * 12).round();
      for (var i = 0; i < count; i++) {
        await tester.pump(Duration(microseconds: (duration / count * 1000000).round()));
        await capture(duration / count);
      }
    }
    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      final offset = tester.getCenter(finder);
      taps.add({'time': clock, 'x': offset.dx, 'y': offset.dy});
      await tester.tap(finder);
      await animate(.42);
      await tester.pumpAndSettle();
    }
    void begin(String name) { shot = name; start = clock; }
    Future<void> end(double duration) async {
      final remaining = duration - (clock - start);
      expect(remaining, greaterThanOrEqualTo(0), reason: '$shot exceeded its timeline');
      if (remaining > .001) await capture(remaining);
      scenes.add({'id': shot, 'start': start, 'end': clock});
      File('${output.path}/frames.json').writeAsStringSync(jsonEncode({
        'width': 390, 'height': 844, 'pixelRatio': 2,
        'frames': frames, 'taps': taps, 'scenes': scenes,
      }));
      // Progress messages only; image pixels are saved to the capture directory.
      print('Captured $shot: ${start.toStringAsFixed(2)}–${clock.toStringAsFixed(2)}');
    }
    void clearMessages() {
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    }

    begin('intro');
    await end(4);

    begin('register');
    await tap(find.text('New here? Create an account'));
    await tester.enterText(find.byType(TextField).at(0), 'Nadia Rahman');
    await tester.enterText(find.byType(TextField).at(1), 'nadia.preview@example.com');
    await tester.ensureVisible(find.text('Register'));
    await tester.pumpAndSettle();
    await capture(.65);
    for (var i = 1; i <= 8; i++) {
      await tester.enterText(find.byType(TextField).at(2), 'Preview9'.substring(0, i));
      await tester.pump();
      await capture(.11);
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await capture(.55);
    await tap(find.text('Register'));
    await end(5);

    begin('login');
    clearMessages();
    await tester.enterText(find.byType(TextField).at(1), 'Preview9');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await capture(.65);
    await tap(find.text('Sign in'));
    expect(store.signedIn, isTrue);
    // Prepare profile details on this same local candidate, between shots.
    await store.updateProfile('Nadia Rahman', '012-000 1234', 'Metro City, Central Region', 'Flutter, Dart, teamwork');
    await store.saveResume('Nadia - Graduate CV', 'Diploma in Information Technology\nFlutter and Dart\nStudent mobile app project\nTeamwork and communication');
    await tester.pumpAndSettle();
    await end(3);

    begin('discover');
    await capture(.9);
    await tap(find.byTooltip('Save job').first);
    await capture(1.1);
    clearMessages();
    await tester.pumpAndSettle();
    await tap(find.text('View & apply').first);
    await end(6);

    begin('apply');
    await capture(.55);
    await tap(find.text('Apply'));
    await capture(.65);
    await tap(find.text('Confirm'));
    await capture(.7);
    clearMessages();
    await tester.pumpAndSettle();
    await tap(find.text('Applied'));
    expect(store.values('applied'), contains('flutter'));
    await end(5);

    begin('progress');
    await tap(find.text('Simulate interview'));
    await capture(.65);
    clearMessages();
    await tester.pumpAndSettle();
    await tap(find.widgetWithText(NavigationDestination, 'Calendar'));
    expect(store.events.any((e) => e['id'] == 'interview-flutter'), isTrue);
    await end(4);

    begin('learning');
    await tap(find.widgetWithText(NavigationDestination, 'Learning'));
    await capture(.8);
    await tap(find.text('Enrol in demo session').first);
    await capture(.65);
    clearMessages();
    await tester.pumpAndSettle();
    await tap(find.widgetWithText(NavigationDestination, 'Calendar'));
    expect(store.values('enrolled'), contains('dart'));
    await end(5);

    begin('together');
    await tap(find.widgetWithText(NavigationDestination, 'Companies'));
    await capture(1.2);
    await tap(find.widgetWithText(NavigationDestination, 'Profile'));
    await end(4);

    begin('outro');
    await end(4);
    expect(clock, closeTo(40, .001));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
