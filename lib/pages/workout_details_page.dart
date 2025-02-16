import 'package:flutter/material.dart';
import 'dart:async'; // For Timer functionality
import '../models/exercise.dart';
import '../models/exercise_result.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../providers/workout_provider.dart';
import 'package:provider/provider.dart';

class WorkoutDetailsPage extends StatefulWidget {
  final WorkoutPlan workoutPlan;

  const WorkoutDetailsPage({super.key, required this.workoutPlan});

  @override
  _WorkoutDetailsPageState createState() => _WorkoutDetailsPageState();
}

class _WorkoutDetailsPageState extends State<WorkoutDetailsPage> {
  late Map<String, int> _actualOutputs;
  late Map<String, Stopwatch> _stopwatches; // Track stopwatches for each exercise
  late Map<String, Timer> _timers; // Track timers for updating the UI

  @override
  void initState() {
    super.initState();
    _actualOutputs = {for (var exercise in widget.workoutPlan.exercises) exercise.name: 0};
    _stopwatches = {for (var exercise in widget.workoutPlan.exercises) exercise.name: Stopwatch()};
    _timers = {};
  }

  @override
  void dispose() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _saveWorkout(BuildContext context) {
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

    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    workoutProvider.addWorkout(workout);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Workout saved successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutPlan.name),
        backgroundColor: Colors.teal,
      ),
      body: Column(
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
              onPressed: () => _saveWorkout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text('Save Workout', style: TextStyle(color: Colors.blueAccent[600])),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseInput(BuildContext context, Exercise exercise) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced padding for compactness
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 8),
            if (exercise.unit == 'seconds')
              _buildSecondsInput(exercise),
            if (exercise.unit == 'meters')
              _buildMetersInput(exercise),
            if (exercise.unit == 'repetitions')
              _buildRepetitionsInput(exercise),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondsInput(Exercise exercise) {
    final stopwatch = _stopwatches[exercise.name]!;
    final isRunning = stopwatch.isRunning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_formatTime(stopwatch.elapsedMilliseconds)} / ${exercise.targetOutput} seconds',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: OutlineInputBorder(),
                  suffixText: '/${exercise.targetOutput}',
                ),
                onChanged: (value) {
                  setState(() {
                    _actualOutputs[exercise.name] = int.tryParse(value) ?? 0;
                    if (_actualOutputs[exercise.name]! > exercise.targetOutput) {
                      _actualOutputs[exercise.name] = exercise.targetOutput;
                    }
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isRunning) {
                    stopwatch.stop();
                    _timers[exercise.name]?.cancel();
                  } else {
                    stopwatch.start();
                    _timers[exercise.name] = Timer.periodic(Duration(milliseconds: 10), (_) {
                      setState(() {});
                    });
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isRunning ? Colors.red[400] : Colors.green[400],
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Text(isRunning ? 'Stop' : 'Start', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  stopwatch.reset();
                  _actualOutputs[exercise.name] = 0;
                  _timers[exercise.name]?.cancel();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[500],
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Text('Reset', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetersInput(Exercise exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_actualOutputs[exercise.name]} / ${exercise.targetOutput} meters',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: OutlineInputBorder(),
                  suffixText: '/${exercise.targetOutput}',
                ),
                onChanged: (value) {
                  setState(() {
                    _actualOutputs[exercise.name] = int.tryParse(value) ?? 0;
                    if (_actualOutputs[exercise.name]! > exercise.targetOutput) {
                      _actualOutputs[exercise.name] = exercise.targetOutput;
                    }
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Slider(
          value: _actualOutputs[exercise.name]?.toDouble() ?? 0,
          min: 0,
          max: exercise.targetOutput.toDouble(),
          divisions: exercise.targetOutput,
          onChanged: (value) {
            setState(() {
              _actualOutputs[exercise.name] = value.toInt();
            });
          },
        ),
      ],
    );
  }

  Widget _buildRepetitionsInput(Exercise exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_actualOutputs[exercise.name]} / ${exercise.targetOutput} repetitions',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: OutlineInputBorder(),
                  suffixText: '/${exercise.targetOutput}',
                ),
                onChanged: (value) {
                  setState(() {
                    _actualOutputs[exercise.name] = int.tryParse(value) ?? 0;
                    if (_actualOutputs[exercise.name]! > exercise.targetOutput) {
                      _actualOutputs[exercise.name] = exercise.targetOutput;
                    }
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: Colors.red[400], size: 18),
              onPressed: () {
                setState(() {
                  if (_actualOutputs[exercise.name]! > 0) {
                    _actualOutputs[exercise.name] = _actualOutputs[exercise.name]! - 1;
                  }
                });
              },
            ),
            Text(
              '${_actualOutputs[exercise.name]}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: Colors.green[400], size: 18),
              onPressed: () {
                setState(() {
                  if (_actualOutputs[exercise.name]! < exercise.targetOutput) {
                    _actualOutputs[exercise.name] = _actualOutputs[exercise.name]! + 1;
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    return '$seconds';
  }
}