import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/workout_provider.dart';
import 'pages/workout_history_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WorkoutProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WorkoutHistoryPage(),
    );
  }
}
