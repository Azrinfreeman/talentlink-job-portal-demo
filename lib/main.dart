import 'package:flutter/material.dart';

import 'demo/demo_app.dart';
import 'demo/demo_store.dart';

/// Entry point. The app runs entirely offline on fictional sample data.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await DemoStore.load();
  runApp(DemoApp(store: store));
}
