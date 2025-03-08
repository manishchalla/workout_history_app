import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../models/workout_plan.dart';
import '../../services/firestore_service.dart';
import '../workout_details_page.dart';

class WorkoutWaitingScreen extends StatefulWidget {
  final WorkoutPlan workoutPlan;
  final String workoutType;
  final String sharedKey;

  const WorkoutWaitingScreen({
    super.key,
    required this.workoutPlan,
    required this.workoutType,
    required this.sharedKey,
  });

  @override
  State<WorkoutWaitingScreen> createState() => _WorkoutWaitingScreenState();
}

class _WorkoutWaitingScreenState extends State<WorkoutWaitingScreen> {
  StreamSubscription? _workoutSubscription;
  bool _isWaiting = true;
  Map<String, dynamic>? _workoutData;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _listenForWorkoutStart();
  }

  void _listenForWorkoutStart() {
    _workoutSubscription = FirebaseFirestore.instance
        .collection('group_workouts')
        .where('invite_code', isEqualTo: widget.sharedKey)
        .where('is_active', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final workoutDoc = snapshot.docs.first;
      final workoutData = workoutDoc.data();

      setState(() {
        _workoutData = workoutData;
      });

      final status = workoutData['status'] as String? ?? 'waiting';

      if (status == 'active' && _isWaiting) {
        setState(() {
          _isWaiting = false;
        });

        // Navigate to workout screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDetailsPage(
              workoutPlan: widget.workoutPlan,
              workoutType: widget.workoutType,
              sharedKey: widget.sharedKey,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _workoutSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = widget.workoutType == 'Competitive'
        ? Colors.orange
        : Colors.blue;

    // Get participants from workout data
    Map<String, dynamic> participants = {};
    if (_workoutData != null && _workoutData!['participants'] != null) {
      participants = Map<String, dynamic>.from(_workoutData!['participants']);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Waiting for Workout'),
        backgroundColor: themeColor,
      ),
      body: Column(
        children: [
          // Animated waiting indicator
          Container(
            padding: EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.hourglass_top,
                    color: themeColor,
                    size: 60,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Waiting for Host to Start',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The workout will begin when the host starts it',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16),
                  LinearProgressIndicator(
                    backgroundColor: themeColor.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                ],
              ),
            ),
          ),

          // Workout details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workout Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.workoutPlan.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${widget.workoutType} Workout',
                          style: TextStyle(
                            color: themeColor,
                          ),
                        ),
                        Divider(),
                        Text(
                          '${widget.workoutPlan.exercises.length} Exercises',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        ...widget.workoutPlan.exercises.take(3).map((exercise) =>
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text('• ${exercise.name}: ${exercise.targetOutput} ${exercise.unit}'),
                            )
                        ),
                        if (widget.workoutPlan.exercises.length > 3)
                          Text('• And ${widget.workoutPlan.exercises.length - 3} more...'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Participants
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.workoutType == 'Competitive' ? 'Participants' : 'Team Members',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${participants.length}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: participants.isEmpty
                        ? Center(
                      child: Text(
                        'Waiting for others to join...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                        : ListView.builder(
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final entry = participants.entries.elementAt(index);
                        final userId = entry.key;
                        final userData = entry.value;
                        final isCreator = userData['is_creator'] == true;
                        final joinedAt = userData['joined_at'] as Timestamp?;
                        final joinTime = joinedAt != null
                            ? "${joinedAt.toDate().hour}:${joinedAt.toDate().minute.toString().padLeft(2, '0')}"
                            : "Unknown";

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCreator ? themeColor : Colors.grey[300],
                            child: Icon(
                              isCreator ? Icons.star : Icons.person,
                              color: isCreator ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          title: Text(
                            isCreator
                                ? (userId == _firestoreService.currentUserId ? "You (Host)" : "Host")
                                : (userId == _firestoreService.currentUserId ? "You" :
                            widget.workoutType == 'Competitive' ? "Participant" : "Team Member"),
                            style: TextStyle(
                              fontWeight: isCreator || userId == _firestoreService.currentUserId ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text('Joined at $joinTime'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}