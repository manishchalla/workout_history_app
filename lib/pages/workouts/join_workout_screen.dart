import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_plan.dart';
import '../../providers/workout_provider.dart';
import '../workout_details_page.dart';

class JoinWorkoutScreen extends StatefulWidget {
  const JoinWorkoutScreen({super.key});

  @override
  _JoinWorkoutScreenState createState() => _JoinWorkoutScreenState();
}

class _JoinWorkoutScreenState extends State<JoinWorkoutScreen> {
  final TextEditingController _inviteCodeController = TextEditingController();

  void _joinWorkout(BuildContext context) async {
    final inviteCode = _inviteCodeController.text.trim();
    if (inviteCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter an invite code.')),
      );
      return;
    }

    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);

    try {
      // Fetch the workout details using the invite code
      final workoutData = await workoutProvider.getGroupWorkout(inviteCode);

      // Navigate to the workout details page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutDetailsPage(
            workoutPlan: WorkoutPlan.fromJson(workoutData), // Convert Firestore data to WorkoutPlan
            workoutType: 'Competitive',
            sharedKey: inviteCode,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join workout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Join Workout'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _inviteCodeController,
              decoration: InputDecoration(
                labelText: 'Enter Invite Code',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _joinWorkout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('Join Workout', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}