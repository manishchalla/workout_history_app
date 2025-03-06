import 'package:flutter/material.dart';
import 'package:workout_app/pages/workouts/workout_result_page.dart';
import '../models/exercise.dart';
import '../models/exercise_result.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../providers/workout_provider.dart';
import 'package:provider/provider.dart';


class WorkoutDetailsPage extends StatefulWidget {
  final WorkoutPlan workoutPlan;
  final String workoutType; // "Solo", "Collaborative", or "Competitive"
  final String sharedKey; // Shared key for group workouts

  const WorkoutDetailsPage({
    super.key,
    required this.workoutPlan,
    required this.workoutType,
    required this.sharedKey,
  });

  @override
  _WorkoutDetailsPageState createState() => _WorkoutDetailsPageState();
}

class _WorkoutDetailsPageState extends State<WorkoutDetailsPage> {
  late Map<String, int> _actualOutputs;
  bool _isSaving = false; // For loading indicator during save

  @override
  void initState() {
    super.initState();
    _actualOutputs = {for (var exercise in widget.workoutPlan.exercises) exercise.name: 0};
  }

  String? _validateInput(String? value, int max) {
    if (value == null || value.isEmpty) return 'Value is required';
    final intValue = int.tryParse(value);
    if (intValue == null) return 'Enter a valid number';
    if (intValue < 0 || intValue > max) return 'Value must be between 0 and $max';
    return null;
  }

  void _saveWorkout(BuildContext context) async {
    setState(() => _isSaving = true); // Show loading indicator
    try {
      // Validate all inputs before saving
      for (var exercise in widget.workoutPlan.exercises) {
        final error = _validateInput(_actualOutputs[exercise.name]?.toString(), exercise.targetOutput);
        if (error != null) {
          print('Validation failed for ${exercise.name}: $error');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error in ${exercise.name}: $error')));
          return;
        }
      }

      print('All inputs are valid. Creating workout object...');

      // Create workout object
      List<ExerciseResult> results = widget.workoutPlan.exercises.map((exercise) {
        return ExerciseResult(
          exercise: exercise,
          actualOutput: _actualOutputs[exercise.name]!,
        );
      }).toList();

      Workout workout = Workout(
        id: null,
        date: DateTime.now(),
        results: results,
      );

      print('Adding workout to provider...');
      final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);

      if (widget.workoutType == 'Solo') {
        // Save solo workout to SQLite
        await workoutProvider.addWorkout(workout);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Solo workout saved successfully!')));
      } else {
        // Handle group workouts (collaborative or competitive)
        if (widget.sharedKey.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Shared key is required for group workouts.')));
          return;
        }

        if (widget.workoutType == 'Collaborative') {
          // Create or join a collaborative workout
          await workoutProvider.createGroupWorkout(widget.workoutType, widget.sharedKey, results);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Collaborative workout created/joined successfully!')));
        } else if (widget.workoutType == 'Competitive') {
          // Create or join a competitive workout
          await workoutProvider.joinGroupWorkout(widget.sharedKey, results);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Competitive workout joined successfully!')));
        }
      }

      // Navigate to the Results Page after saving
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutResultsPage(sharedKey: widget.sharedKey),
        ),
      );
    } catch (e) {
      print('Error during save: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save workout: $e')));
    } finally {
      setState(() => _isSaving = false); // Hide loading indicator
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.workoutType} Workout: ${widget.workoutPlan.name}'),
        backgroundColor: Colors.teal,
      ),
      body: widget.workoutPlan.exercises.isEmpty
          ? Center(child: Text('No exercises available.', style: TextStyle(fontSize: 18, color: Colors.grey)))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.workoutPlan.exercises.length,
              itemBuilder: (context, index) {
                final exercise = widget.workoutPlan.exercises[index];
                return _buildExerciseInput(context, exercise);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => _saveWorkout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Workout', style: TextStyle(color: Colors.blueAccent)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseInput(BuildContext context, Exercise exercise) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_actualOutputs[exercise.name]} / ${exercise.targetOutput} ${exercise.unit}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                if (exercise.unit == 'seconds')
                  SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        border: const OutlineInputBorder(),
                        errorText: _validateInput(_actualOutputs[exercise.name]?.toString(), exercise.targetOutput),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _actualOutputs[exercise.name] = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (exercise.unit == 'meters')
              Slider(
                value: _actualOutputs[exercise.name]?.toDouble() ?? 0,
                min: 0,
                max: exercise.targetOutput.toDouble(),
                divisions: exercise.targetOutput,
                label: '${_actualOutputs[exercise.name]} / ${exercise.targetOutput} meters',
                onChanged: (value) {
                  setState(() {
                    _actualOutputs[exercise.name] = value.toInt();
                  });
                },
              ),
            if (exercise.unit == 'repetitions')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: Colors.red[400], size: 28),
                    onPressed: () {
                      setState(() {
                        if (_actualOutputs[exercise.name]! > 0) {
                          _actualOutputs[exercise.name] = _actualOutputs[exercise.name]! - 1;
                        }
                      });
                    },
                    tooltip: 'Decrease repetitions',
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '${_actualOutputs[exercise.name]}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Colors.green[400], size: 28),
                    onPressed: () {
                      setState(() {
                        if (_actualOutputs[exercise.name]! < exercise.targetOutput) {
                          _actualOutputs[exercise.name] = _actualOutputs[exercise.name]! + 1;
                        }
                      });
                    },
                    tooltip: 'Increase repetitions',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}