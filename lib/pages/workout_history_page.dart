import 'package:flutter/material.dart';
import '../models/fake_data.dart';
import 'workout_details_page.dart';

class WorkoutHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout History'),
      ),
      body: ListView.builder(
        itemCount: fakeWorkouts.length,
        itemBuilder: (context, index) {
          final workout = fakeWorkouts[index];
          return ListTile(
            title: Text('Workout on ${workout.date.toString()}'),
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
    );
  }
}