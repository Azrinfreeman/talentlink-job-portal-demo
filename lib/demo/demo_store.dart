import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'demo_data.dart';

/// Local demo state only; no HTTP calls or production credentials.
class DemoStore extends ChangeNotifier {
  DemoStore(this._prefs);
  static const storageKey = 'talentlink_demo_v1';
  final SharedPreferences _prefs;
  Map<String, dynamic> _accounts = {};
  String? _session;
  bool _remember = false;
  Map<String, dynamic>? get user =>
      _session == null ? null : _accounts[_session] as Map<String, dynamic>?;
  bool get signedIn => user != null;
  String get email => _session ?? '';
  List<String> values(String key) => List<String>.from(user?[key] ?? []);
  List<Map<String, dynamic>> get events => (user?['events'] as List? ?? [])
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  List<Map<String, dynamic>> get resumes => (user?['resumes'] as List? ?? [])
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  static Future<DemoStore> load() async {
    final store = DemoStore(await SharedPreferences.getInstance());
    final saved = store._prefs.getString(storageKey);
    if (saved != null) {
      final data = jsonDecode(saved) as Map<String, dynamic>;
      store._accounts = Map<String, dynamic>.from(data['accounts']);
      store._session = data['session'] as String?;
      store._remember = store._session != null;
    }
    if (!store._accounts.containsKey(demoEmail)) {
      store._accounts[demoEmail] = store._account('Aina Demo', demoPassword);
      final sample = store._accounts[demoEmail] as Map<String, dynamic>;
      sample['phone'] = '012-000 1234';
      sample['address'] = 'Metro City, Central Region';
      sample['skills'] = 'Flutter, teamwork, communication';
      sample['saved'] = ['designer'];
      sample['applied'] = ['engineer', 'content'];
      sample['interviews'] = ['engineer'];
      sample['achieved'] = ['content'];
      sample['events'] = [
        {
          'id': 'sample-interview',
          'title': 'Demo interview: Project Engineer',
          'date': demoDate(3)
        },
      ];
      sample['resumes'] = [
        {
          'id': 'sample-resume',
          'title': 'Aina — Graduate CV',
          'text':
              'Career goal: Build useful digital products.\nEducation: Diploma in Information Technology.\nSkills: Flutter, Dart, teamwork.\nExperience: Student mobile app project.'
        },
      ];
      await store._save();
    }
    return store;
  }

  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
  Map<String, dynamic> _account(String name, String password) {
    final random = Random.secure();
    final salt =
        base64Url.encode(List.generate(24, (_) => random.nextInt(256)));
    return {
      'name': name,
      'salt': salt,
      'passwordHash': _hash(salt, password),
      'phone': '',
      'address': '',
      'skills': '',
      'saved': <String>[],
      'applied': <String>[],
      'interviews': <String>[],
      'achieved': <String>[],
      'enrolled': <String>[],
      'events': <Map<String, dynamic>>[],
      'resumes': <Map<String, dynamic>>[]
    };
  }

  Future<void> _save() async {
    final ok = await _prefs.setString(
        storageKey,
        jsonEncode({
          'accounts': _accounts,
          'session': _remember ? _session : null,
        }));
    if (!ok) throw StateError('Could not save demo data on this device.');
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    email = email.trim().toLowerCase();
    if (name.trim().isEmpty) {
      throw const FormatException('Enter your full name.');
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      throw const FormatException('Enter a valid email address.');
    }
    if (password.length < 6) {
      throw const FormatException('Use at least 6 password characters.');
    }
    if (_accounts.containsKey(email)) {
      throw const FormatException('This email is already registered.');
    }
    _accounts[email] = _account(name.trim(), password);
    await _save();
  }

  Future<void> login(String email, String password,
      {bool remember = false}) async {
    email = email.trim().toLowerCase();
    final account = _accounts[email] as Map<String, dynamic>?;
    if (account == null ||
        account['passwordHash'] != _hash(account['salt'], password)) {
      throw const FormatException('Email or password is incorrect.');
    }
    _session = email;
    _remember = remember;
    await _save();
  }

  Future<void> logout() async {
    _session = null;
    _remember = false;
    await _save();
  }

  Future<void> updateProfile(
      String name, String phone, String address, String skills) async {
    if (name.trim().isEmpty) {
      throw const FormatException('Name cannot be empty.');
    }
    user!.addAll({
      'name': name.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'skills': skills.trim()
    });
    await _save();
  }

  Future<void> changePassword(String current, String next) async {
    if (user!['passwordHash'] != _hash(user!['salt'], current)) {
      throw const FormatException('Current password is incorrect.');
    }
    if (next.length < 6) {
      throw const FormatException('Use at least 6 password characters.');
    }
    user!['passwordHash'] = _hash(user!['salt'], next);
    await _save();
  }

  Future<void> toggleSaved(String id) async {
    final saved = values('saved');
    saved.contains(id) ? saved.remove(id) : saved.add(id);
    user!['saved'] = saved;
    await _save();
  }

  Future<void> apply(String id) async {
    final applied = values('applied');
    if (applied.contains(id)) {
      throw const FormatException('You have already applied for this job.');
    }
    applied.add(id);
    user!['applied'] = applied;
    await _save();
  }

  Future<void> withdraw(String id) async {
    for (final key in ['applied', 'interviews', 'achieved']) {
      user![key] = values(key)..remove(id);
    }
    user!['events'] = events.where((e) => e['id'] != 'interview-$id').toList();
    await _save();
  }

  Future<void> advanceApplication(String id) async {
    if (!values('applied').contains(id)) {
      throw const FormatException('Apply for this job first.');
    }
    if (!values('interviews').contains(id)) {
      user!['interviews'] = values('interviews')..add(id);
      final job = demoJobs.firstWhere((j) => j['id'] == id);
      user!['events'] = events
        ..add({
          'id': 'interview-$id',
          'title': 'Demo interview: ${job['title']}',
          'date': demoDate(3)
        });
    } else if (!values('achieved').contains(id)) {
      user!['achieved'] = values('achieved')..add(id);
    }
    await _save();
  }

  Future<void> toggleEnrollment(Map<String, Object> course) async {
    final id = course['id'] as String;
    final enrolled = values('enrolled');
    final calendar = events.where((e) => e['id'] != 'course-$id').toList();
    if (enrolled.contains(id)) {
      enrolled.remove(id);
    } else {
      enrolled.add(id);
      calendar.add({
        'id': 'course-$id',
        'title': course['title'],
        'date': demoDate(course['days'] as int)
      });
    }
    user!['enrolled'] = enrolled;
    user!['events'] = calendar;
    await _save();
  }

  Future<void> addEvent(String title, String date) async {
    if (title.trim().isEmpty) {
      throw const FormatException('Enter an event title.');
    }
    user!['events'] = events
      ..add({
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'title': title.trim(),
        'date': date
      });
    await _save();
  }

  Future<void> deleteEvent(String id) async {
    user!['events'] = events.where((e) => e['id'] != id).toList();
    await _save();
  }

  Future<void> saveResume(String title, String text, {String? id}) async {
    if (title.trim().isEmpty || text.trim().isEmpty) {
      throw const FormatException('Enter a résumé title and content.');
    }
    user!['resumes'] = resumes.where((r) => r['id'] != id).toList()
      ..add({
        'id': id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        'title': title.trim(),
        'text': text.trim()
      });
    await _save();
  }

  Future<void> deleteResume(String id) async {
    user!['resumes'] = resumes.where((r) => r['id'] != id).toList();
    await _save();
  }
}
