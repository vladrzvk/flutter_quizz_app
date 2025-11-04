import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les dépendances
  await di.initializeDependencies();

  runApp(const MyApp());
}
