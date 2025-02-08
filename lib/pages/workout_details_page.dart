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
            title: Text('Workout Details'),
          ),
          body: ListView.builder(
            itemCount: workout.results.length,
            itemBuilder: (context, index) {
              final result = workout.results[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: ListTile(
                  title: Text(result.exercise.name),
                  subtitle: Text('Target: ${result.exercise.targetOutput} ${result.exercise.unit}, Actual: ${result.actualOutput}'),
                  trailing: Text(
                    result.isSuccessful ? 'Success' : 'Failed',
                    style: TextStyle(
                      color: result.isSuccessful ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: RecentPerformanceWidget(),
        ),
      ],
    );
  }
}