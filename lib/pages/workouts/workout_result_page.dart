import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/exercise_result.dart';
import '../../providers/workout_provider.dart';
import '../home_layout.dart';

class WorkoutResultsPage extends StatelessWidget {
  final String sharedKey;

  const WorkoutResultsPage({super.key, required this.sharedKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Results'),
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false, // Remove the back button
      ),
      body: WillPopScope(
        onWillPop: () async => false, // Disable back navigation
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchWorkoutData(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error loading results: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No results found.'));
            }

            final workoutData = snapshot.data!;
            final rawResults = Map<String, dynamic>.from(workoutData['results']);

            // Convert raw results into a Map<String, List<ExerciseResult>>
            final results = <String, List<ExerciseResult>>{};
            rawResults.forEach((userId, userResults) {
              results[userId] = (userResults as List<dynamic>).map((result) {
                return ExerciseResult.fromJson(result);
              }).toList();
            });

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Participants: ${results.length}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final userId = results.keys.elementAt(index);
                        final userResults = results[userId]!;
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User $userId',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                ...userResults.map((result) => ListTile(
                                  title: Text(result.exercise.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Target: ${result.exercise.targetOutput} ${result.exercise.unit}'),
                                      Text('Actual: ${result.actualOutput} ${result.exercise.unit}'),
                                      result.isSuccessful
                                          ? Text('Status: Achieved', style: TextStyle(color: Colors.green))
                                          : Text('Status: Not Achieved', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => HomeLayout()),
                            (route) => false, // Clear the navigation stack
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text('Return to Home', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchWorkoutData(BuildContext context) async {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    return await workoutProvider.getGroupWorkout(sharedKey);
  }
}