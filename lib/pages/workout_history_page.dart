import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import 'workout_details_page.dart';
import 'workout_recording_page.dart';
import '../models/workout_plan.dart';

class WorkoutHistoryPage extends StatelessWidget {
  const WorkoutHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);

    return ListView.builder(
      itemCount: workoutProvider.workouts.length,
      itemBuilder: (context, index) {
        final workout = workoutProvider.workouts[index];
        final formattedDateTime = DateFormat('MMM/dd/yyyy, h:mm a').format(workout.date);
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Add margin
          child: ListTile(
            title: Text('Workout on $formattedDateTime'),
            subtitle: Text('${workout.successfulExercises}/${workout.totalExercises} exercises completed'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkoutDetailsPage(workout: workout),
                ),
              );
            },
          ),
        );
      },
    );
  }
}