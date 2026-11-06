import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:job_management/demo/demo_data.dart';
import 'package:job_management/demo/demo_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('Registration validates duplicates and login validates passwords',
      () async {
    final store = await DemoStore.load();
    await expectLater(store.register('', 'bad', '123'), throwsFormatException);
    await store.register('Candidate', ' Person@Example.com ', 'Test123!');
    await expectLater(store.register('Other', 'person@example.com', 'Test123!'),
        throwsFormatException);
    await expectLater(
        store.login('person@example.com', 'wrong'), throwsFormatException);
    await store.login('person@example.com', 'Test123!');
    expect(store.user!['name'], 'Candidate');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(DemoStore.storageKey), isNot(contains('Test123!')));
  });
  test('Data persists, sessions restore and accounts remain isolated',
      () async {
    var store = await DemoStore.load();
    await store.register('Candidate', 'person@example.com', 'Test123!');
    await store.login('person@example.com', 'Test123!', remember: true);
    await store.toggleSaved('flutter');
    await store.apply('flutter');
    await expectLater(store.apply('flutter'), throwsFormatException);
    await store.advanceApplication('flutter');
    expect(store.events.any((e) => e['id'] == 'interview-flutter'), isTrue);
    await store.advanceApplication('flutter');
    await store.toggleEnrollment(demoCourses.first);
    await store.addEvent('First event', '2026-11-01');
    await store.addEvent('Second event', '2026-11-01');
    await store.updateProfile(
        'Updated Candidate', '0123456789', 'Shah Alam', 'Dart');
    await store.saveResume('My CV', 'Education and experience');
    await store.changePassword('Test123!', 'New123!');
    store = await DemoStore.load();
    expect(store.signedIn, isTrue);
    expect(store.values('achieved'), ['flutter']);
    expect(store.events.where((e) => e['date'] == '2026-11-01').length, 2);
    expect(store.resumes.single['title'], 'My CV');
    expect(store.user!['name'], 'Updated Candidate');
    await store.logout();
    store = await DemoStore.load();
    expect(store.signedIn, isFalse);
    await store.login('person@example.com', 'New123!');
    expect(store.values('saved'), ['flutter']);
    await store.withdraw('flutter');
    expect(store.values('applied'), isEmpty);
    expect(store.values('interviews'), isEmpty);
    expect(store.values('achieved'), isEmpty);
    await store.toggleEnrollment(demoCourses.first);
    expect(store.values('enrolled'), isEmpty);
    expect(store.events.any((e) => e['id'] == 'course-dart'), isFalse);
    await store.logout();
    await store.login(demoEmail, demoPassword);
    expect(store.user!['name'], 'Aina Demo');
    expect(store.values('saved'), isNot(contains('flutter')));
    store = await DemoStore.load();
    expect(store.signedIn, isFalse, reason: 'Remember me was not selected');
  });
}
