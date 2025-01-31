import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';

class RecentPerformanceWidget extends StatelessWidget {
  const RecentPerformanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final recentWorkouts = workoutProvider.recentWorkouts;

    if (recentWorkouts.isEmpty) {
      return Card(
        margin: EdgeInsets.all(8.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No workouts recorded in the last 7 days.',
            style: TextStyle(fontSize: 16.0),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    int totalExercises = recentWorkouts.fold(0, (sum, workout) => sum + workout.totalExercises);
    int successfulExercises = recentWorkouts.fold(0, (sum, workout) => sum + workout.successfulExercises);
    double successRate = (successfulExercises / totalExercises) * 100;

    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Last 7 Days Performance',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              'Total Exercises: $totalExercises',
              style: TextStyle(fontSize: 16.0),
            ),
            Text(
              'Successful Exercises: $successfulExercises',
              style: TextStyle(fontSize: 16.0),
            ),
            Text(
              'Success Rate: ${successRate.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 16.0, color: successRate >= 75 ? Colors.green : Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
