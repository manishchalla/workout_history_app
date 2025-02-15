import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/exercise_result.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../providers/workout_provider.dart';
import '../widgets/recent_performance_widget.dart';

class WorkoutRecordingPage extends StatefulWidget {
  final WorkoutPlan workoutPlan;

  const WorkoutRecordingPage({super.key, required this.workoutPlan});

  @override
  _WorkoutRecordingPageState createState() => _WorkoutRecordingPageState();
}

class _WorkoutRecordingPageState extends State<WorkoutRecordingPage> {
  late Map<String, int> _exerciseValues;

  @override
  void initState() {
    super.initState();
    // Initialize _exerciseValues as a Map<String, int>
    _exerciseValues = Map<String, int>.fromEntries(
      widget.workoutPlan.exercises.map((exercise) => MapEntry(
        exercise.name,
        exercise.unit == 'meters' ? 100 : 0,
      )),
    );
  }

  @override
  void didUpdateWidget(covariant WorkoutRecordingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize _exerciseValues if the workout plan changes
    if (oldWidget.workoutPlan.exercises != widget.workoutPlan.exercises) {
      _exerciseValues = Map<String, int>.fromEntries(
        widget.workoutPlan.exercises.map((exercise) => MapEntry(
          exercise.name,
          exercise.unit == 'meters' ? 100 : 0,
        )),
      );
    }
  }

  void _finishWorkout() {
    final results = widget.workoutPlan.exercises.map((exercise) {
      return ExerciseResult(
        exercise: exercise,
        actualOutput: _exerciseValues[exercise.name] ?? 0,
      );
    }).toList();

    final workout = Workout(date: DateTime.now(), results: results);
    Provider.of<WorkoutProvider>(context, listen: false).addWorkout(workout);
    Navigator.pop(context);
  }

  Widget _buildInputField(Exercise exercise) {
    try {
      final value = _exerciseValues[exercise.name] ?? 0;
      final isSliderExercise = exercise.name.toLowerCase().contains('lunge') ||
          exercise.name.toLowerCase().contains('push-up') ||
          exercise.name.toLowerCase().contains('squat');

      if (isSliderExercise) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: exercise.targetOutput.toDouble(),
                divisions: exercise.targetOutput,
                label: '$value',
                onChanged: (newValue) {
                  setState(() {
                    _exerciseValues[exercise.name] = newValue.toInt();
                  });
                },
              ),
            ),
            Text(
              '$value / ${exercise.targetOutput}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }

      switch (exercise.unit) {
        case 'repetitions':
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                onPressed: () {
                  setState(() {
                    if (value > 0) {
                      _exerciseValues[exercise.name] = value - 1;
                    }
                  });
                },
              ),
              Text(
                '$value / ${exercise.targetOutput}',
                style: const TextStyle(fontSize: 14),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () {
                  setState(() {
                    if (value < exercise.targetOutput) {
                      _exerciseValues[exercise.name] = value + 1;
                    }
                  });
                },
              ),
            ],
          );

        case 'seconds':
          return SizedBox(
            width: 100,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: exercise.unit,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (text) {
                setState(() {
                  _exerciseValues[exercise.name] = int.tryParse(text) ?? 0;
                });
              },
            ),
          );

        case 'meters':
          return DropdownButton<int>(
            value: _exerciseValues[exercise.name] ?? 100,
            items: [100, 200, 500, 1000].map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value ${exercise.unit}'),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _exerciseValues[exercise.name] = newValue!;
              });
            },
          );

        default:
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Unsupported Unit',
                style: TextStyle(color: Colors.red),
              ),
              Text('Unit: ${exercise.unit}'),
            ],
          );
      }
    } catch (e) {
      debugPrint('Error building input field for ${exercise.name}: $e');
      return const Center(child: Text('Error loading input'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Workout'),
      ),
      body: Column(
        children: [
          // Recent Performance Widget at the top
          RecentPerformanceWidget(),
          const Divider(height: 1, thickness: 1), // Optional: Add a divider for better separation

          // Expanded ListView for exercises
          Expanded(
            child: ListView.builder(
              itemCount: widget.workoutPlan.exercises.length,
              itemBuilder: (context, index) {
                final exercise = widget.workoutPlan.exercises[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                exercise.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Target: ${exercise.targetOutput} ${exercise.unit}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _buildInputField(exercise),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Save Workout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _finishWorkout,
              child: const Text('Save Workout'),
            ),
          ),
        ],
      ),
    );
  }
}