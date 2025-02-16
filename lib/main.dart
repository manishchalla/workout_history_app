import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/workout_provider.dart';
import 'pages/home_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the WorkoutProvider and load data
  final workoutProvider = WorkoutProvider();
  await workoutProvider.loadWorkouts(); // Load saved workouts
  await workoutProvider.loadSavedWorkoutPlans(); // Load saved workout plans

  runApp(
    ChangeNotifierProvider.value(
      value: workoutProvider,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout App',
      theme: ThemeData(
        primarySwatch: Colors.teal, // Primary color for the app
        scaffoldBackgroundColor: Colors.grey[100], // Light background for pages
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal, // AppBar color
          foregroundColor: Colors.white, // Text color on AppBar
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        cardTheme: CardTheme(
          color: Colors.white, // Card background color
          elevation: 4, // Add shadow for depth
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Colors.teal, // Color for LinearProgressIndicator
        ),
      ),
      home: HomeLayout(), // Set the HomeLayout as the main screen
    );
  }
}