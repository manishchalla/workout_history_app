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

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout History'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: workoutProvider.workouts.length,
              itemBuilder: (context, index) {
                final workout = workoutProvider.workouts[index];
                final formattedDateTime = DateFormat('MMM/dd/yyyy, h:mm a').format(workout.date);
                return ListTile(
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
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutRecordingPage(workoutPlan: exampleWorkoutPlan),
                  ),
                );
              },
              child: Text('Start New Workout'),
            ),
          ),
        ],
      ),
    );
  }
}
