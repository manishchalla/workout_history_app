import 'package:flutter/material.dart';
import '../models/workout.dart';

class WorkoutDetailsPage extends StatelessWidget {
  final Workout workout;

  WorkoutDetailsPage({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Details'),
      ),
      body: ListView.builder(
        itemCount: workout.results.length,
        itemBuilder: (context, index) {
          final result = workout.results[index];
          return ListTile(
            title: Text(result.exercise.name),
            subtitle: Text('Target: ${result.exercise.targetOutput} ${result.exercise.unit}, Actual: ${result.actualOutput}'),
            trailing: Icon(
              result.isSuccessful ? Icons.check : Icons.close,
              color: result.isSuccessful ? Colors.green : Colors.red,
            ),
          );
        },
      ),
    );
  }
}