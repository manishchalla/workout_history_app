import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise_result.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../providers/workout_provider.dart';
import '../widgets/recent_performance_widget.dart'; // Import the widget

class WorkoutRecordingPage extends StatefulWidget {
  final WorkoutPlan workoutPlan;

  const WorkoutRecordingPage({super.key, required this.workoutPlan});

  @override
  _WorkoutRecordingPageState createState() => _WorkoutRecordingPageState();
}

class _WorkoutRecordingPageState extends State<WorkoutRecordingPage> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var exercise in widget.workoutPlan.exercises) {
      _controllers[exercise.name] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _finishWorkout() {
    final results = widget.workoutPlan.exercises.map((exercise) {
      final actualOutput = int.tryParse(_controllers[exercise.name]?.text ?? '0') ?? 0;
      return ExerciseResult(exercise: exercise, actualOutput: actualOutput);
    }).toList();

    final workout = Workout(date: DateTime.now(), results: results);
    Provider.of<WorkoutProvider>(context, listen: false).addWorkout(workout);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record Workout'), // Page title
      ),
      body: Column(
        children: [
          RecentPerformanceWidget(), // Recent Performance below the page title
          Expanded(
            child: ListView.builder(
              itemCount: widget.workoutPlan.exercises.length,
              itemBuilder: (context, index) {
                final exercise = widget.workoutPlan.exercises[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Add margin
                  child: ListTile(
                    title: Text(exercise.name),
                    subtitle: Text('Target: ${exercise.targetOutput} ${exercise.unit}'),
                    trailing: SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _controllers[exercise.name],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: exercise.unit,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0), // Add padding
            child: ElevatedButton(
              onPressed: _finishWorkout,
              child: Text('Save Workout'), // Updated button text
            ),
          ),
        ],
      ),
    );
  }
}