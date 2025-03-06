import 'package:flutter/material.dart';
import '../../models/workout_plan.dart';
import '../../providers/workout_provider.dart';
import 'package:provider/provider.dart';

import '../workout_details_page.dart';

class CompetitiveWorkoutScreen extends StatefulWidget {
  final WorkoutPlan workoutPlan;

  const CompetitiveWorkoutScreen({super.key, required this.workoutPlan});

  @override
  _CompetitiveWorkoutScreenState createState() => _CompetitiveWorkoutScreenState();
}

class _CompetitiveWorkoutScreenState extends State<CompetitiveWorkoutScreen> {
  late String _inviteCode; // Automatically generated invite code

  @override
  void initState() {
    super.initState();
    _inviteCode = DateTime.now().millisecondsSinceEpoch.toString(); // Simple unique key
  }

  void _startWorkout(BuildContext context) async {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);

    try {
      // Create the group workout in Firestore
      await workoutProvider.createGroupWorkout('Competitive', _inviteCode, []);

      // Navigate to the workout details page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutDetailsPage(
            workoutPlan: widget.workoutPlan,
            workoutType: 'Competitive',
            sharedKey: _inviteCode,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start workout: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Competitive Workout: ${widget.workoutPlan.name}'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite Code:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            SelectableText(
              _inviteCode,
              style: TextStyle(fontSize: 18, color: Colors.blueAccent),
            ),
            SizedBox(height: 16),
            Text(
              'Workout Details:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              widget.workoutPlan.exercises.map((e) => e.name).join(', '),
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () => _startWorkout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('Start Workout', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}