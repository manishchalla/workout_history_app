import 'package:flutter/material.dart';
import 'package:workout_app/pages/workouts/collaborative_workout_screen.dart';
import 'package:workout_app/pages/workouts/competitive_workout_screen.dart';
import '../models/workout_plan.dart';
import '../providers/workout_provider.dart';
import 'package:provider/provider.dart';
import 'workout_details_page.dart';

class WorkoutRecordingPage extends StatefulWidget {
  const WorkoutRecordingPage({super.key});

  @override
  _WorkoutRecordingPageState createState() => _WorkoutRecordingPageState();
}

class _WorkoutRecordingPageState extends State<WorkoutRecordingPage> {
  String? _selectedWorkoutType; // Tracks the selected workout type
  final TextEditingController _sharedKeyController = TextEditingController(); // For shared key input

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final savedPlans = workoutProvider.savedWorkoutPlans;

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Workout Plan'),
        backgroundColor: Colors.teal,
      ),
      body: savedPlans.isEmpty
          ? Center(
        child: Text(
          'No workout plans available.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: savedPlans.length,
        itemBuilder: (context, index) {
          final plan = savedPlans[index];
          return _buildWorkoutPlanCard(context, plan);
        },
      ),
    );
  }

  Widget _buildWorkoutPlanCard(BuildContext context, WorkoutPlan plan) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red[400]),
                  onPressed: () async {
                    if (plan.id == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Unable to delete plan: Missing ID.')),
                      );
                      return;
                    }
                    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
                    await workoutProvider.deleteWorkoutPlan(plan.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Workout plan deleted successfully.')),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '${plan.exercises.length} Exercises',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Text(
              plan.exercises.map((e) => e.name).join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkoutDetailsPage(
                              workoutPlan: plan,
                              workoutType: 'Solo',
                              sharedKey: '',
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.person, color: Colors.teal),
                      tooltip: 'Solo Workout',
                    ),
                    Text(
                      'Solo',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CollaborativeWorkoutScreen(workoutPlan: plan),
                          ),
                        );
                      },
                      icon: Icon(Icons.people, color: Colors.lightBlueAccent[600]),
                      tooltip: 'Collaborative Workout',
                    ),
                    Text(
                      'Collaborative',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompetitiveWorkoutScreen(workoutPlan: plan),
                          ),
                        );
                      },
                      icon: Icon(Icons.flag, color: Colors.orangeAccent),
                      tooltip: 'Competitive Workout',
                    ),
                    Text(
                      'Competitive',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}