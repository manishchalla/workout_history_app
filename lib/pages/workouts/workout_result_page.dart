import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../models/exercise.dart';
import '../../models/exercise_result.dart';
import '../../services/firestore_service.dart';
import '../home_layout.dart';

class WorkoutResultsPage extends StatefulWidget {
  final String sharedKey;

  const WorkoutResultsPage({super.key, required this.sharedKey});

  @override
  _WorkoutResultsPageState createState() => _WorkoutResultsPageState();
}

class _WorkoutResultsPageState extends State<WorkoutResultsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _workoutData;
  StreamSubscription? _workoutSubscription;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _firestoreService.currentUserId;
    _setupWorkoutListener();
  }

  void _setupWorkoutListener() {
    _workoutSubscription = FirebaseFirestore.instance
        .collection('group_workouts')
        .where('invite_code', isEqualTo: widget.sharedKey)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _isLoading = false;
        if (snapshot.docs.isNotEmpty) {
          _workoutData = snapshot.docs.first.data();
          _errorMessage = null;
        } else {
          _errorMessage = 'Workout not found';
        }
      });
    }, onError: (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading results: $error';
      });
    });
  }

  @override
  void dispose() {
    _workoutSubscription?.cancel();
    super.dispose();
  }

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
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : _buildResultsContent(),
      ),
    );
  }

  Widget _buildResultsContent() {
    if (_workoutData == null) {
      return Center(child: Text('No workout data available'));
    }

    final workoutType = _workoutData!['type'] as String? ?? 'Solo';
    final participants = Map<String, dynamic>.from(_workoutData!['participants'] ?? {});
    final workoutPlanData = _workoutData!['workout_plan'] as Map<String, dynamic>?;

    if (workoutPlanData == null) {
      return Center(child: Text('Workout plan data is missing'));
    }

    final workoutName = workoutPlanData['name'] as String? ?? 'Workout';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workoutName,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 8),

          Text(
            'Type: $workoutType',
            style: TextStyle(fontSize: 18, color: _getWorkoutTypeColor(workoutType)),
          ),

          SizedBox(height: 8),

          Text(
            'Participants: ${participants.length}',
            style: TextStyle(fontSize: 16),
          ),

          SizedBox(height: 16),

          // Show appropriate results based on workout type
          workoutType == 'Competitive'
              ? _buildCompetitiveResults(participants)
              : _buildCollaborativeResults(participants, workoutPlanData),

          SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomeLayout()),
                      (route) => false, // Clear the navigation stack
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Return to Home', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitiveResults(Map<String, dynamic> participants) {
    List<MapEntry<String, dynamic>> participantsList = participants.entries.toList();

    // Count participants who have submitted results
    final participantsWithResults = participantsList.where((entry) =>
    entry.value['results'] != null &&
        (entry.value['results'] as List).isNotEmpty
    ).length;

    // Calculate rankings
    Map<String, int> rankings = _firestoreService.calculateRankings(participants);

    // Sort participants by rank
    participantsList.sort((a, b) {
      final rankA = rankings[a.key] ?? 999;
      final rankB = rankings[b.key] ?? 999;
      return rankA.compareTo(rankB);
    });

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Competitive Results:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '$participantsWithResults/${participantsList.length} submitted',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),

          // Show waiting message if not all participants have submitted
          if (participantsWithResults < participantsList.length)
            Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_bottom, color: Colors.amber.shade800),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Waiting for other participants to submit their results. Rankings will update automatically.',
                      style: TextStyle(color: Colors.amber.shade800),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              itemCount: participantsList.length,
              itemBuilder: (context, index) {
                final entry = participantsList[index];
                final userId = entry.key;
                final userData = entry.value;
                final rank = rankings[userId] ?? 0;

                final results = userData['results'] != null
                    ? List<Map<String, dynamic>>.from(userData['results'])
                    : <Map<String, dynamic>>[];

                // Calculate total score
                int totalScore = 0;
                for (var result in results) {
                  totalScore += (result['actual_output'] ?? 0) as int;
                }

                // Highlight the current user
                final isCurrentUser = userId == _currentUserId;

                return Card(
                  elevation: 3,
                  margin: EdgeInsets.only(bottom: 12),
                  color: isCurrentUser ? Colors.orange.shade50 : null,
                  shape: isCurrentUser
                      ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.orange.shade300, width: 2),
                  )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (rank > 0) ...[
                              _buildRankBadge(rank),
                              SizedBox(width: 8),
                            ],

                            Text(
                              isCurrentUser ? 'You' : 'Participant ${index + 1}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCurrentUser ? Colors.orange.shade800 : null,
                              ),
                            ),

                            Spacer(),

                            if (results.isNotEmpty)
                              Text(
                                'Score: $totalScore',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              )
                            else
                              Text(
                                'Pending...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),

                        Divider(),

                        if (results.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('No results submitted yet.'),
                          )
                        else
                          ...results.map((result) {
                            final exerciseName = result['name'];
                            final targetOutput = result['target'];
                            final actualOutput = result['actual_output'];
                            final unit = result['unit'];
                            final isSuccess = actualOutput >= targetOutput;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(exerciseName),
                                  Row(
                                    children: [
                                      Text(
                                        '$actualOutput/$targetOutput $unit',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSuccess ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        isSuccess ? Icons.check_circle : Icons.cancel,
                                        size: 16,
                                        color: isSuccess ? Colors.green : Colors.red,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaborativeResults(Map<String, dynamic> participants, Map<String, dynamic> workoutPlanData) {
    final exercises = (workoutPlanData['exercises'] as List<dynamic>)
        .map((e) => Exercise(
      name: e['name'],
      targetOutput: (e['target'] as num).toInt(),
      unit: e['unit'],
    ))
        .toList();

    // Calculate combined results
    final combinedResults = _calculateCombinedResults(participants, exercises);

    // Count participants who have submitted results
    final participantsWithResults = participants.entries.where((entry) =>
    entry.value['results'] != null &&
        (entry.value['results'] as List).isNotEmpty
    ).length;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collaborative Results:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '$participantsWithResults/${participants.length} submitted',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),

          SizedBox(height: 4),

          Text(
            'Your team has combined their efforts!',
            style: TextStyle(fontSize: 14, color: Colors.blue[600]),
          ),

          // Show waiting message if not all participants have submitted
          if (participantsWithResults < participants.length)
            Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.blue.shade700),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Waiting for all team members to complete the workout. Results will update as more members participate.',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                final combinedOutput = combinedResults[exercise.name] ?? 0;
                final isSuccess = combinedOutput >= exercise.targetOutput;

                // Find current user's contribution
                int userContribution = 0;
                if (_currentUserId != null &&
                    participants[_currentUserId] != null &&
                    participants[_currentUserId]['results'] != null) {
                  for (var result in participants[_currentUserId]['results']) {
                    if (result['name'] == exercise.name) {
                      userContribution = (result['actual_output'] ?? 0) as int;
                      break;
                    }
                  }
                }

                // Calculate contribution percentage
                double contributionPercentage = combinedOutput > 0
                    ? (userContribution / combinedOutput) * 100
                    : 0;

                return Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 8),
                  color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              exercise.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  isSuccess ? Icons.check_circle : Icons.cancel,
                                  color: isSuccess ? Colors.green : Colors.red,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  isSuccess ? 'Success!' : 'Not achieved',
                                  style: TextStyle(
                                    color: isSuccess ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: 8),

                        Text('Target: ${exercise.targetOutput} ${exercise.unit}'),

                        SizedBox(height: 4),

                        Text(
                          'Combined team result: $combinedOutput ${exercise.unit}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: 8),

                        LinearProgressIndicator(
                          value: (combinedOutput / exercise.targetOutput).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isSuccess ? Colors.green : Colors.red,
                          ),
                        ),

                        SizedBox(height: 8),

                        // Show user's contribution
                        if (userContribution > 0)
                          Container(
                            margin: EdgeInsets.only(top: 8),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your contribution:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: userContribution,
                                      child: Container(
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.horizontal(
                                            left: Radius.circular(4),
                                            right: combinedOutput == userContribution ? Radius.circular(4) : Radius.zero,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$userContribution',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: combinedOutput - userContribution,
                                      child: Container(
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.horizontal(
                                            right: Radius.circular(4),
                                            left: userContribution == 0 ? Radius.circular(4) : Radius.zero,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${combinedOutput - userContribution}',
                                          style: TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'You contributed ${contributionPercentage.toStringAsFixed(1)}% of the total',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateCombinedResults(Map<String, dynamic> participants, List<Exercise> exercises) {
    Map<String, int> combinedResults = {};

    // Initialize combined results with 0 for each exercise
    for (var exercise in exercises) {
      combinedResults[exercise.name] = 0;
    }

    // Add up all participant results
    participants.forEach((userId, data) {
      if (data['results'] != null) {
        for (var result in data['results']) {
          String exerciseName = result['name'];
          num actualOutput = result['actual_output'] ?? 0;
          combinedResults[exerciseName] = (combinedResults[exerciseName] ?? 0) + actualOutput.toInt();
        }
      }
    });

    return combinedResults;
  }

  Widget _buildRankBadge(int rank) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getRankColor(rank),
      ),
      child: Center(
        child: Text(
          rank.toString(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.blueGrey; // Silver
      case 3:
        return Colors.brown; // Bronze
      default:
        return Colors.grey;
    }
  }

  Color _getWorkoutTypeColor(String type) {
    switch (type) {
      case 'Competitive':
        return Colors.orange;
      case 'Collaborative':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }
}