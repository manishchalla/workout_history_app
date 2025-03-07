import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/workout_plan.dart';
import '../../services/firestore_service.dart';
import '../workout_details_page.dart';

class CompetitiveWorkoutScreen extends StatefulWidget {
  final WorkoutPlan workoutPlan;

  const CompetitiveWorkoutScreen({super.key, required this.workoutPlan});

  @override
  _CompetitiveWorkoutScreenState createState() => _CompetitiveWorkoutScreenState();
}

class _CompetitiveWorkoutScreenState extends State<CompetitiveWorkoutScreen> {
  late String _inviteCode;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isCreating = false;
  String? _workoutId;

  @override
  void initState() {
    super.initState();
    // Generate a unique invite code
    _inviteCode = _firestoreService.generateInviteCode();
  }

  void _copyInviteCode() {
    Clipboard.setData(ClipboardData(text: _inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Invite code copied to clipboard'),
          duration: Duration(seconds: 1)
      ),
    );
  }

  Future<void> _startWorkout() async {
    setState(() {
      _isCreating = true;
    });

    try {
      // Create the competitive workout in Firestore
      _workoutId = await _firestoreService.createGroupWorkout(
        workoutType: 'Competitive',
        inviteCode: _inviteCode,
        workoutPlan: widget.workoutPlan,
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to create workout: $e'),
            duration: Duration(seconds: 1)
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Competitive Workout'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.workoutPlan.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),

            // Invite code section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invite Code',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _inviteCode,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: _copyInviteCode,
                          tooltip: 'Copy invite code',
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Share this code with friends to join the competitive workout.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Workout details section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('${widget.workoutPlan.exercises.length} Exercises:'),
                    SizedBox(height: 8),
                    ...widget.workoutPlan.exercises.map((exercise) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text('• ${exercise.name}: ${exercise.targetOutput} ${exercise.unit}'),
                    )),
                  ],
                ),
              ),
            ),

            Spacer(),

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _startWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isCreating
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Start Competitive Workout', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}