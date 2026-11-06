import 'package:flutter/material.dart';
import 'demo_data.dart';
import 'demo_store.dart';

class DemoApp extends StatelessWidget {
  const DemoApp({super.key, required this.store});
  final DemoStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'TalentLink',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xffb92332)),
            useMaterial3: true,
            inputDecorationTheme:
                const InputDecorationTheme(border: OutlineInputBorder()),
            cardTheme:
                const CardThemeData(margin: EdgeInsets.symmetric(vertical: 6))),
        home: ListenableBuilder(
            listenable: store,
            builder: (context, _) => store.signedIn
                ? DemoHome(store: store)
                : DemoAuth(store: store)),
      );
}

String errorMessage(Object error) => error is FormatException
    ? error.message
    : 'Could not save this change. Please try again.';

class DemoAuth extends StatefulWidget {
  const DemoAuth({super.key, required this.store});
  final DemoStore store;
  @override
  State<DemoAuth> createState() => _DemoAuthState();
}

class _DemoAuthState extends State<DemoAuth> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool registering = false, remember = false, busy = false, obscure = true;
  String? error;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (registering) {
        await widget.store.register(name.text, email.text, password.text);
        if (!mounted) return;
        setState(() {
          registering = false;
          password.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Account created. Sign in with your new account.')));
      } else {
        await widget.store.login(email.text, password.text, remember: remember);
      }
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: AutofillGroup(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            Image.asset('assets/logo-talentlink.png',
                                height: 95, fit: BoxFit.contain),
                            const SizedBox(height: 20),
                            Text('Your next opportunity starts here',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                                textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            const Text(
                                'LOCAL DEMO • Fictional data • No server connection',
                                textAlign: TextAlign.center),
                            const SizedBox(height: 24),
                            Text(
                                registering
                                    ? 'Create an account'
                                    : 'Welcome back',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 16),
                            if (registering) ...[
                              TextField(
                                  controller: name,
                                  autofillHints: const [AutofillHints.name],
                                  decoration: const InputDecoration(
                                      labelText: 'Full name')),
                              const SizedBox(height: 12),
                            ],
                            TextField(
                                controller: email,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.username],
                                decoration:
                                    const InputDecoration(labelText: 'Email')),
                            const SizedBox(height: 12),
                            TextField(
                                controller: password,
                                obscureText: obscure,
                                autofillHints: [
                                  registering
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password
                                ],
                                onSubmitted: (_) {
                                  if (!busy) submit();
                                },
                                decoration: InputDecoration(
                                    labelText: 'Password',
                                    helperText: registering
                                        ? 'At least 6 characters'
                                        : null,
                                    suffixIcon: IconButton(
                                        tooltip: obscure
                                            ? 'Show password'
                                            : 'Hide password',
                                        onPressed: () =>
                                            setState(() => obscure = !obscure),
                                        icon: Icon(obscure
                                            ? Icons.visibility
                                            : Icons.visibility_off)))),
                            if (!registering)
                              CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title:
                                      const Text('Remember me on this device'),
                                  value: remember,
                                  onChanged: busy
                                      ? null
                                      : (v) => setState(() => remember = v!)),
                            if (error != null)
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(error!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error))),
                            const SizedBox(height: 12),
                            FilledButton(
                                onPressed: busy ? null : submit,
                                child: Text(busy
                                    ? 'Please wait…'
                                    : registering
                                        ? 'Register'
                                        : 'Sign in')),
                            TextButton(
                                onPressed: busy
                                    ? null
                                    : () => setState(() {
                                          registering = !registering;
                                          error = null;
                                        }),
                                child: Text(registering
                                    ? 'Already registered? Sign in'
                                    : 'New here? Create an account')),
                            if (!registering) ...[
                              const Divider(),
                              const Text('Try the sample account',
                                  textAlign: TextAlign.center),
                              const SelectableText(
                                  '$demoEmail\nPassword: $demoPassword',
                                  textAlign: TextAlign.center),
                              OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () {
                                          email.text = demoEmail;
                                          password.text = demoPassword;
                                          submit();
                                        },
                                  child: const Text('Explore demo account')),
                              TextButton(
                                  onPressed: () => showDialog<void>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                              title: const Text(
                                                  'Demo account help'),
                                              content: const Text(
                                                  'The sample account uses the credentials shown above. For a local account you created, use its original password or register a different email. This offline demo cannot send password reset emails.'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(c),
                                                    child: const Text('Close'))
                                              ])),
                                  child: const Text('Need help signing in?')),
                            ],
                          ])))))));
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key, required this.store});
  final DemoStore store;
  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  DemoStore get store => widget.store;
  int tab = 0;
  String query = '', jobType = 'All', jobView = 'All', learningType = 'All';
  bool busy = false;
  final search = TextEditingController();
  static const tabs = ['Jobs', 'Learning', 'Companies', 'Calendar', 'Profile'];
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> act(Future<void> Function() action, String message) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> confirm(String title, String message) async =>
      await showDialog<bool>(
          context: context,
          builder: (c) =>
              AlertDialog(title: Text(title), content: Text(message), actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Confirm')),
              ])) ??
      false;

  /// Collect text in a scrollable form. Controllers live until its route closes.
  Future<List<String>?> form(
      String title, List<String> labels, List<String> initial,
      {bool secret = false, bool multiline = false}) async {
    final controllers =
        initial.map((s) => TextEditingController(text: s)).toList();
    final result = await showDialog<List<String>>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(title),
                content: SizedBox(
                    width: 440,
                    child: SingleChildScrollView(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                                labels.length,
                                (i) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: TextField(
                                        controller: controllers[i],
                                        obscureText: secret,
                                        minLines:
                                            multiline && i == labels.length - 1
                                                ? 5
                                                : 1,
                                        maxLines:
                                            multiline && i == labels.length - 1
                                                ? 10
                                                : 1,
                                        decoration: InputDecoration(
                                            labelText: labels[i]))))))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(
                          c, controllers.map((t) => t.text).toList()),
                      child: const Text('Save'))
                ]));
    // Dialog exit animations can still use its TextFields for a frame.
    Future<void>.delayed(const Duration(seconds: 1), () {
      for (final c in controllers) {
        c.dispose();
      }
    });
    return result;
  }

  Widget empty(String text) => Padding(
      padding: const EdgeInsets.all(32),
      child: Center(child: Text(text, textAlign: TextAlign.center)));
  Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge));
  Map<String, String> company(String id) =>
      demoCompanies.firstWhere((c) => c['id'] == id);

  Future<void> jobDetail(Map<String, String> job) async {
    final employer = company(job['company']!);
    await showDialog<void>(
        context: context,
        builder: (c) => ListenableBuilder(
            listenable: store,
            builder: (c, _) {
              final applied = store.values('applied').contains(job['id']);
              return AlertDialog(
                  title: Text(job['title']!),
                  content: SizedBox(
                      width: 480,
                      child: SingleChildScrollView(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            Text(
                                '${employer['name']}\n${employer['location']}\n${job['type']} • ${job['salary']}'),
                            const SizedBox(height: 16),
                            Text(job['description']!),
                            const SizedBox(height: 16),
                            Text(
                                '${job['positions']} positions • Applications close ${demoDate(30)}'),
                            const SizedBox(height: 12),
                            const Text(
                                'Demo application: your local profile is used. No information is sent to an employer.'),
                          ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Close')),
                    FilledButton(
                        onPressed: applied
                            ? null
                            : () async {
                                Navigator.pop(c);
                                if (await confirm('Apply for this job?',
                                    'Submit a demo application for ${job['title']}?')) {
                                  await act(() => store.apply(job['id']!),
                                      'Demo application submitted. View it under Applied.');
                                }
                              },
                        child: Text(applied ? 'Already applied' : 'Apply'))
                  ]);
            }));
  }

  Widget jobs() {
    final keys = {
      'Saved': 'saved',
      'Applied': 'applied',
      'Interviews': 'interviews',
      'Achieved': 'achieved'
    };
    final filtered = demoJobs
        .where((j) =>
            (jobView == 'All' ||
                store.values(keys[jobView]!).contains(j['id'])) &&
            (jobType == 'All' || j['type'] == jobType) &&
            '${j['title']} ${company(j['company']!)['name']} ${company(j['company']!)['location']}'
                .toLowerCase()
                .contains(query.toLowerCase()))
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      heading('Find your next opportunity'),
      TextField(
          controller: search,
          onChanged: (s) => setState(() => query = s),
          decoration: const InputDecoration(
              labelText: 'Search jobs, companies or locations',
              prefixIcon: Icon(Icons.search))),
      const SizedBox(height: 12),
      Wrap(
          spacing: 8,
          children: ['All', ...keys.keys]
              .map((v) => ChoiceChip(
                  label: Text(v),
                  selected: jobView == v,
                  onSelected: (_) => setState(() => jobView = v)))
              .toList()),
      DropdownButtonFormField<String>(
          value: jobType,
          decoration: const InputDecoration(labelText: 'Job type'),
          items: ['All', ...demoJobs.map((j) => j['type']!).toSet()]
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) => setState(() => jobType = v!)),
      if (filtered.isEmpty)
        empty('No jobs here yet. Browse All to save or apply for a job.'),
      ...filtered.map((j) {
        final id = j['id']!;
        final applied = store.values('applied').contains(id);
        final interview = store.values('interviews').contains(id);
        final achieved = store.values('achieved').contains(id);
        return Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(j['title']!,
                                style:
                                    Theme.of(context).textTheme.titleMedium)),
                        IconButton(
                            tooltip: store.values('saved').contains(id)
                                ? 'Unsave job'
                                : 'Save job',
                            onPressed: busy
                                ? null
                                : () => act(() => store.toggleSaved(id),
                                    'Saved jobs updated.'),
                            icon: Icon(store.values('saved').contains(id)
                                ? Icons.bookmark
                                : Icons.bookmark_border))
                      ]),
                      Text(
                          '${company(j['company']!)['name']} • ${company(j['company']!)['location']}'),
                      Text('${j['type']} • ${j['salary']}'),
                      if (applied)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(achieved
                                ? 'Offer received (demo)'
                                : interview
                                    ? 'Interview scheduled (demo)'
                                    : 'Application submitted')),
                      Wrap(spacing: 8, children: [
                        TextButton(
                            onPressed: () => jobDetail(j),
                            child: Text(
                                applied ? 'View details' : 'View & apply')),
                        if (applied && !achieved)
                          TextButton(
                              onPressed: busy
                                  ? null
                                  : () => act(
                                      () => store.advanceApplication(id),
                                      interview
                                          ? 'Demo offer received.'
                                          : 'Demo interview added to your calendar.'),
                              child: Text(interview
                                  ? 'Simulate offer'
                                  : 'Simulate interview')),
                        if (applied)
                          TextButton(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      if (await confirm('Withdraw application?',
                                          'Remove this demo application and its status?')) {
                                        await act(() => store.withdraw(id),
                                            'Application withdrawn.');
                                      }
                                    },
                              child: const Text('Withdraw')),
                      ]),
                    ])));
      }),
    ]);
  }

  Widget learning() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        heading('Build your skills'),
        Wrap(
            spacing: 8,
            children: ['All', 'Training', 'Webinar', 'Enrolled']
                .map((v) => ChoiceChip(
                    label: Text(v),
                    selected: learningType == v,
                    onSelected: (_) => setState(() => learningType = v)))
                .toList()),
        ...demoCourses
            .where((c) =>
                learningType == 'All' ||
                (learningType == 'Enrolled'
                    ? store.values('enrolled').contains(c['id'])
                    : c['type'] == learningType))
            .map((course) {
          final enrolled = store.values('enrolled').contains(course['id']);
          return Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course['title'] as String,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                            '${course['type']} • ${demoDate(course['days'] as int)}\n${course['venue']}'),
                        const SizedBox(height: 12),
                        Text(course['description'] as String),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                            onPressed: busy
                                ? null
                                : () => act(
                                    () => store.toggleEnrollment(course),
                                    enrolled
                                        ? 'Enrolment cancelled; calendar updated.'
                                        : 'Enrolled! Session added to your calendar.'),
                            child: Text(enrolled
                                ? 'Cancel enrolment'
                                : 'Enrol in demo session')),
                      ])));
        }),
        if (learningType == 'Enrolled' && store.values('enrolled').isEmpty)
          empty(
              'No enrolments yet. Browse training and webinars to get started.'),
      ]);

  Widget companies() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        heading('Meet the companies'),
        ...demoCompanies.map((c) => Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['name']!,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('${c['industry']} • ${c['location']}'),
                      const SizedBox(height: 12),
                      Text(c['about']!),
                      TextButton(
                          onPressed: () => showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                      title: Text(c['name']!),
                                      content: SingleChildScrollView(
                                          child: Text(
                                              '${c['about']}\n\nIndustry: ${c['industry']}\nLocation: ${c['location']}\nSample phone: ${c['phone']}\n\nFictional company; contact details are for display only.')),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Close'))
                                      ])),
                          child: const Text('Company details')),
                      TextButton(
                          onPressed: () => setState(() {
                                tab = 0;
                                query = c['name']!;
                                search.text = query;
                                jobView = 'All';
                                jobType = 'All';
                              }),
                          child: const Text('View company jobs')),
                    ])))),
      ]);

  Future<void> addEvent() async {
    final day = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 730)));
    if (day == null || !mounted) return;
    final result = await form('New calendar event', ['Event title'], ['']);
    if (result != null && mounted) {
      await act(
          () =>
              store.addEvent(result[0], day.toIso8601String().substring(0, 10)),
          'Event saved.');
    }
  }

  Widget calendar() {
    final events = store.events
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      heading('Your calendar'),
      const Text(
          'Training enrolments and simulated interviews appear here alongside your own events.'),
      const SizedBox(height: 12),
      FilledButton.icon(
          onPressed: busy ? null : addEvent,
          icon: const Icon(Icons.add),
          label: const Text('Add event')),
      if (events.isEmpty)
        empty('No events yet. Add an event or enrol in a session.'),
      ...events.map((e) => Card(
          child: ListTile(
              leading: const Icon(Icons.event),
              title: Text(e['title']),
              subtitle: Text(e['date']),
              trailing: IconButton(
                  tooltip: 'Delete event',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: busy
                      ? null
                      : () async {
                          if (await confirm('Delete event?',
                              'This removes the calendar entry. Training enrolment remains unchanged.')) {
                            await act(() => store.deleteEvent(e['id']),
                                'Event removed.');
                          }
                        })))),
    ]);
  }

  Future<void> editResume([Map<String, dynamic>? resume]) async {
    final result = await form(
        resume == null ? 'Create a demo résumé' : 'Edit résumé',
        ['Title', 'Education, skills and experience'],
        [resume?['title'] ?? '', resume?['text'] ?? ''],
        multiline: true);
    if (result != null && mounted) {
      await act(() => store.saveResume(result[0], result[1], id: resume?['id']),
          'Résumé saved locally.');
    }
  }

  Future<void> appraisal() => showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
              title: const Text('Sample appraisal'),
              content: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text(
                        'Illustrative assessment only; these scores are fictional.'),
                    const SizedBox(height: 16),
                    for (final entry in {
                      'Functional skills': .82,
                      'Interpersonal skills': .90,
                      'Leadership': .75
                    }.entries) ...[
                      Text('${entry.key}: ${(entry.value * 100).round()}%'),
                      LinearProgressIndicator(value: entry.value),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                        'Overall: 82%\n\nStrong collaboration and problem solving. Suggested next step: practise presenting a project and attend a skills workshop.'),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Close'))
              ]));

  Widget profile() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        heading(store.user!['name']),
        Text(store.email),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Phone: ${store.user!['phone'] == '' ? 'Not added' : store.user!['phone']}'),
                      Text(
                          'Address: ${store.user!['address'] == '' ? 'Not added' : store.user!['address']}'),
                      Text(
                          'Skills: ${store.user!['skills'] == '' ? 'Not added' : store.user!['skills']}'),
                      TextButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit profile'),
                          onPressed: busy
                              ? null
                              : () async {
                                  final r = await form(
                                      'Edit profile',
                                      [
                                        'Full name',
                                        'Phone',
                                        'Address',
                                        'Skills'
                                      ],
                                      ['name', 'phone', 'address', 'skills']
                                          .map((k) => store.user![k] as String)
                                          .toList());
                                  if (r != null && mounted) {
                                    await act(
                                        () => store.updateProfile(
                                            r[0], r[1], r[2], r[3]),
                                        'Profile saved.');
                                  }
                                }),
                    ]))),
        heading('Your activity'),
        Text(
            '${store.values('saved').length} saved jobs • ${store.values('applied').length} applications • ${store.values('enrolled').length} enrolments'),
        TextButton(
            onPressed: appraisal, child: const Text('View sample appraisal')),
        heading('Résumés'),
        const Text('Create and edit local text résumés for the demo.'),
        TextButton.icon(
            onPressed: busy ? null : () => editResume(),
            icon: const Icon(Icons.add),
            label: const Text('Add résumé')),
        if (store.resumes.isEmpty)
          empty('No résumé yet. Add your education, skills and experience.'),
        ...store.resumes.map((r) => Card(
            child: ListTile(
                title: Text(r['title']),
                subtitle: const Text('Saved on this device'),
                onTap: () => editResume(r),
                trailing: IconButton(
                    tooltip: 'Delete résumé',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: busy
                        ? null
                        : () async {
                            if (await confirm('Delete résumé?',
                                'Remove ${r['title']} from this demo account?')) {
                              await act(() => store.deleteResume(r['id']),
                                  'Résumé deleted.');
                            }
                          })))),
        heading('Account'),
        OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    final r = await form('Change demo password',
                        ['Current password', 'New password'], ['', ''],
                        secret: true);
                    if (r != null && mounted) {
                      await act(() => store.changePassword(r[0], r[1]),
                          'Password changed.');
                    }
                  },
            child: const Text('Change password')),
        TextButton(
            onPressed: busy
                ? null
                : () async {
                    if (await confirm('Sign out?',
                        'Your demo data will stay saved on this device.')) {
                      await act(store.logout, 'Signed out.');
                    }
                  },
            child: const Text('Sign out')),
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('TalentLink • ${tabs[tab]}'), actions: [
          IconButton(
              tooltip: 'Activity',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => showDialog<void>(
                  context: context,
                  builder: (c) => AlertDialog(
                          title: const Text('Demo activity'),
                          content: Text(
                              '${store.values('applied').length} job applications\n${store.values('interviews').length} interview invitations\n${store.values('achieved').length} offers\n${store.values('enrolled').length} training enrolments\n\nOpen Jobs or Calendar for details.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(c),
                                child: const Text('Close'))
                          ]))),
        ]),
        body: Column(children: [
          Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.secondaryContainer,
              padding: const EdgeInsets.all(10),
              child: const Text(
                  'LOCAL DEMO • Fictional data • Changes saved on this device',
                  textAlign: TextAlign.center)),
          if (busy) const LinearProgressIndicator(),
          Expanded(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: switch (tab) {
                            0 => jobs(),
                            1 => learning(),
                            2 => companies(),
                            3 => calendar(),
                            _ => profile()
                          })))),
        ]),
        bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (v) => setState(() => tab = v),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.work_outline), label: 'Jobs'),
              NavigationDestination(
                  icon: Icon(Icons.school_outlined), label: 'Learning'),
              NavigationDestination(
                  icon: Icon(Icons.business_outlined), label: 'Companies'),
              NavigationDestination(
                  icon: Icon(Icons.calendar_month), label: 'Calendar'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline), label: 'Profile'),
            ]),
      );
}
