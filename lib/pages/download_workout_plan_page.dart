import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../providers/workout_provider.dart';
import 'package:provider/provider.dart';

import 'home_layout.dart';

class DownloadWorkoutPlanPage extends StatefulWidget {
  const DownloadWorkoutPlanPage({super.key});

  @override
  _DownloadWorkoutPlanPageState createState() => _DownloadWorkoutPlanPageState();
}

class _DownloadWorkoutPlanPageState extends State<DownloadWorkoutPlanPage> {
  final TextEditingController _urlController = TextEditingController();
  WorkoutPlan? _downloadedPlan;
  String? _errorMessage;

  Future<void> _fetchWorkoutPlan() async {
    setState(() {
      _downloadedPlan = null;
      _errorMessage = null;
    });

    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid URL.';
      });
      return;
    }

    try {
      print('Attempting to download workout plan from URL: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print('Response received successfully.');
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('name') && data.containsKey('exercises')) {
          final WorkoutPlan workoutPlan = WorkoutPlan(
            name: data['name'],
            exercises: (data['exercises'] as List<dynamic>)
                .map((e) => Exercise(
              name: e['name'],
              targetOutput: e['target'] ?? 0,
              unit: e['unit'] ?? 'repetitions',
            ))
                .toList(),
          );
          setState(() {
            _downloadedPlan = workoutPlan;
            _errorMessage = null;
          });
          print('Workout plan parsed successfully: ${workoutPlan.name}');
        } else {
          throw Exception('Invalid workout plan structure.');
        }
      } else {
        throw Exception('Failed to download workout plan. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during download: $e');
      setState(() {
        _errorMessage = 'An error occurred while downloading the workout plan: ${e.toString()}';
      });
    }
  }

  void _saveWorkoutPlan() {
    if (_downloadedPlan != null) {
      try {
        final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);

        // Check for duplicate plan names
        workoutProvider.isDuplicatePlan(_downloadedPlan!.name).then((isDuplicate) {
          if (isDuplicate) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('A workout plan with this name already exists.')),
            );
            print('Duplicate workout plan detected.');
          } else {
            // Save the workout plan if no duplicate exists
            workoutProvider.saveWorkoutPlan(_downloadedPlan!);
            print('Workout plan saved successfully.');

            // Navigate back to the home screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeLayout()),
                  (route) => false,
            );
            print('Navigated back to home screen.');
          }
        });
      } catch (e) {
        print('Error while saving workout plan: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Download Workout Plan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Enter Workout Plan URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchWorkoutPlan,
              child: Text('Download Workout Plan'),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            if (_downloadedPlan != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Text(
                      'Workout Plan: ${_downloadedPlan!.name}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _downloadedPlan!.exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _downloadedPlan!.exercises[index];
                          return ListTile(
                            title: Text(exercise.name),
                            subtitle: Text('${exercise.targetOutput} ${exercise.unit}'),
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _saveWorkoutPlan,
                          child: Text('Save Workout Plan'),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _downloadedPlan = null;
                              _urlController.clear();
                            });
                          },
                          child: Text('Discard'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}