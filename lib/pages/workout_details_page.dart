import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../widgets/recent_performance_widget.dart';

class WorkoutDetailsPage extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailsPage({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text('Workout Details'), // Page title
          ),
          body: ListView.builder(
            itemCount: workout.results.length,
            itemBuilder: (context, index) {
              final result = workout.results[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Add margin
                child: ListTile(
                  title: Text(result.exercise.name),
                  subtitle: Text('Target: ${result.exercise.targetOutput} ${result.exercise.unit}, Actual: ${result.actualOutput}'),
                  trailing: Text(
                    result.isSuccessful ? 'Success' : 'Failed', // Use text instead of icons
                    style: TextStyle(
                      color: result.isSuccessful ? Colors.green : Colors.red, // Change text color based on success
                      fontWeight: FontWeight.bold, // Make the text bold
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 0, // Place at the bottom of the screen
          left: 0,
          right: 0,
          child: RecentPerformanceWidget(), // Add the widget here
        ),
      ],
    );
  }
}