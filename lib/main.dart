import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/workout_provider.dart';
import 'pages/workout_history_page.dart';
import 'pages/workout_recording_page.dart';
import 'widgets/recent_performance_widget.dart';
import 'models/workout_plan.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WorkoutProvider(),
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
        primarySwatch: Colors.blue,
      ),
      home: HomeLayout(), // Use the existing layout
    );
  }
}

class HomeLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout App'), // App title
      ),
      body: Column(
        children: [
          RecentPerformanceWidget(), // Recent Performance below the app title
          Expanded(
            child: WorkoutHistoryPage(), // Page content
          ),
          Padding(
            padding: const EdgeInsets.all(16.0), // Add padding
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutRecordingPage(workoutPlan: exampleWorkoutPlan),
                  ),
                );
              },
              child: Text('Add a Workout'), // Updated button text
            ),
          ),
        ],
      ),
    );
  }
}