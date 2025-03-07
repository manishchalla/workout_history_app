import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';

class RecentPerformanceWidget extends StatelessWidget {
  const RecentPerformanceWidget({super.key});

  // Helper function to determine color based on success percentage
  Color _getPerformanceColor(double successPercentage) {
    if (successPercentage >= 75) {
      return Colors.green;
    } else if (successPercentage >= 25) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

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
            'No Recent Performance.',
            style: TextStyle(fontSize: 16.0, color: Colors.teal),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Calculate total exercises and successful exercises
    int totalExercises = 0;
    int successfulExercises = 0;
    int soloWorkouts = 0;
    int groupWorkouts = 0;

    for (var workout in recentWorkouts) {
      totalExercises += workout.results.length;
      successfulExercises += workout.results.where((result) => result.isSuccessful).length;

      if (workout.type == 'Solo') {
        soloWorkouts++;
      } else {
        groupWorkouts++;
      }
    }

    double successPercentage = totalExercises > 0 ? (successfulExercises / totalExercises) * 100 : 0;
    final performanceColor = _getPerformanceColor(successPercentage);

    return Card(
      margin: EdgeInsets.all(8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade50, Colors.teal.shade200],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Last 7 Days Performance',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (soloWorkouts > 0)
                    _buildStatBadge('Solo: $soloWorkouts', Colors.teal),
                  SizedBox(width: 8),
                  if (groupWorkouts > 0)
                    _buildStatBadge('Group: $groupWorkouts', Colors.blue),
                ],
              ),
              SizedBox(height: 8.0),
              Text(
                'Successful Exercises: $successfulExercises / $totalExercises',
                style: TextStyle(fontSize: 16.0, color: Colors.black87),
              ),
              SizedBox(height: 8.0),
              LinearProgressIndicator(
                value: successPercentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(performanceColor),
              ),
              SizedBox(height: 8.0),
              Text(
                '${successPercentage.toStringAsFixed(1)}% Success',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: performanceColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}