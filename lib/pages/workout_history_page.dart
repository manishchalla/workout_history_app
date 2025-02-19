import 'package:flutter/material.dart';
import '../providers/workout_provider.dart';
import 'package:provider/provider.dart';

class WorkoutHistoryPage extends StatelessWidget {
  const WorkoutHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final workouts = workoutProvider.workouts;

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout History'),
      ),
      body: workouts.isEmpty
          ? Center(child: Text('No workouts recorded yet.', style: TextStyle(fontSize: 18, color: Colors.teal)))
          : ListView.builder(
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];

          String formattedDate = '${workout.date.day}/${workout.date.month}/${workout.date.year}';
          String formattedTime = '${workout.date.hour}:${workout.date.minute.toString().padLeft(2, '0')} ${workout.date.hour >= 12 ? 'PM' : 'AM'}';

          int totalExercises = workout.results.length;
          int successfulExercises = workout.results.where((result) => result.actualOutput >= result.exercise.targetOutput).length;

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ExpansionTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$formattedDate at $formattedTime', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    'Success: $successfulExercises/$totalExercises Exercises',
                    style: TextStyle(fontSize: 14, color: Colors.teal),
                  ),
                ],
              ),
              children: workout.results.map((result) {
                bool isSuccess = result.actualOutput >= result.exercise.targetOutput;
                IconData icon = isSuccess ? Icons.check_circle : Icons.cancel;
                Color iconColor = isSuccess ? Colors.green : Colors.red;

                return ListTile(
                  leading: Icon(icon, color: iconColor, size: 30),
                  title: Text(result.exercise.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target: ${result.exercise.targetOutput} ${result.exercise.unit}', style: TextStyle(fontSize: 14)),
                      Text('Actual: ${result.actualOutput} ${result.exercise.unit}', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}