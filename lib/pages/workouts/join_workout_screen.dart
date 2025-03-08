import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../models/workout_plan.dart';
import '../../services/firestore_service.dart';
import '../workout_details_page.dart';
import 'qr_scanner_screen.dart';

class JoinWorkoutScreen extends StatefulWidget {
  const JoinWorkoutScreen({super.key});

  @override
  _JoinWorkoutScreenState createState() => _JoinWorkoutScreenState();
}

class _JoinWorkoutScreenState extends State<JoinWorkoutScreen> {
  final TextEditingController _inviteCodeController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isJoining = false;
  String? _errorMessage;

  Future<void> _joinWorkout() async {
    final inviteCode = _inviteCodeController.text.trim();
    if (inviteCode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an invite code';
      });
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      // Join the group workout
      final workoutData = await _firestoreService.joinGroupWorkout(inviteCode);

      // Extract the workout plan data
      final workoutPlanData = workoutData['workout_plan'];

      if (workoutPlanData == null) {
        throw Exception('Invalid workout data. Please try again with a valid invite code.');
      }

      // Create workout plan object
      final exercises = (workoutPlanData['exercises'] as List)
          .map((e) => Exercise(
        name: e['name'],
        targetOutput: (e['target'] as num).toInt(),
        unit: e['unit'],
      ))
          .toList();

      final workoutPlan = WorkoutPlan(
        name: workoutPlanData['name'],
        exercises: exercises,
      );

      // Determine workout type
      final workoutType = workoutData['type'] ?? 'Competitive';

      // Navigate to the workout details page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutDetailsPage(
            workoutPlan: workoutPlan,
            workoutType: workoutType,
            sharedKey: inviteCode,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isJoining = false;
      });
    }
  }

  void _openQrScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrScannerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Join Workout'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Join a Workout',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),

            // Option 1: Enter Code
            Text(
              'Option 1: Enter Invite Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Ask your friend for the 6-digit invite code.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 12),

            // Invite code input
            TextField(
              controller: _inviteCodeController,
              decoration: InputDecoration(
                labelText: 'Invite Code',
                hintText: 'Enter 6-digit code',
                border: OutlineInputBorder(),
                errorText: _errorMessage,
                prefixIcon: Icon(Icons.key),
              ),
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(fontSize: 20, letterSpacing: 2),
              maxLength: 6,
            ),

            SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isJoining ? null : _joinWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isJoining
                    ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white),
                )
                    : Text('Join Workout', style: TextStyle(fontSize: 18)),
              ),
            ),

            SizedBox(height: 32),

            // Option 2: Scan QR Code
            Text(
              'Option 2: Scan QR Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Scan the QR code shown on your friend\'s device.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openQrScanner,
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Scan QR Code', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}