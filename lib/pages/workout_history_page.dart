import 'package:flutter/material.dart';
import '../providers/workout_provider.dart';
import '../services/firestore_service.dart';
import 'package:provider/provider.dart';

class WorkoutHistoryPage extends StatelessWidget {
  const WorkoutHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final workouts = workoutProvider.workouts;
    final firestoreService = FirestoreService(); // To access user ID and other utilities

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout History'),
      ),
      body: workouts.isEmpty
          ? Center(child: Text('No workouts recorded yet.', style: TextStyle(fontSize: 18, color: Colors.teal)))
          : ListView.builder(
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];

          String formattedDate = '${workout.date.day}/${workout.date.month}/${workout.date.year}';
          String formattedTime = '${workout.date.hour}:${workout.date.minute.toString().padLeft(2, '0')} ${workout.date.hour >= 12 ? 'PM' : 'AM'}';

          int totalExercises = workout.results.length;
          int successfulExercises = workout.results.where((result) => result.actualOutput >= result.exercise.targetOutput).length;

          // Determine card color based on workout type
          Color cardColor;
          if (workout.type == 'Competitive') {
            cardColor = Colors.orange.shade50;
          } else if (workout.type == 'Collaborative') {
            cardColor = Colors.blue.shade50;
          } else {
            cardColor = Colors.white;
          }

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 4,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: workout.type == 'Competitive'
                    ? Colors.orange.shade300
                    : workout.type == 'Collaborative'
                    ? Colors.blue.shade300
                    : Colors.transparent,
                width: workout.type != 'Solo' ? 1 : 0,
              ),
            ),
            child: ExpansionTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$formattedDate at $formattedTime',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      // Badge for workout type
                      if (workout.type != 'Solo')
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: workout.type == 'Competitive'
                                ? Colors.orange.shade200
                                : Colors.blue.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            workout.type,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: workout.type == 'Competitive'
                                  ? Colors.deepOrange
                                  : Colors.blue.shade800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Success: $successfulExercises/$totalExercises Exercises',
                    style: TextStyle(fontSize: 14, color: Colors.teal),
                  ),

                  // For competitive workouts, show rank
                  if (workout.type == 'Competitive' && workout.rank != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          _buildRankBadge(workout.rank!),
                          SizedBox(width: 8),
                          Text(
                            'Your ranking',
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),

                  // For collaborative workouts, show team success message
                  if (workout.type == 'Collaborative')
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.people, color: Colors.blue, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Team effort with ${workout.participantCount ?? '?'} participants',
                            style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              children: [
                // Special header for competitive/collaborative workouts
                if (workout.type != 'Solo')
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: workout.type == 'Competitive'
                        ? Colors.orange.shade100
                        : Colors.blue.shade100,
                    child: Text(
                      workout.type == 'Competitive'
                          ? 'Your Individual Performance'
                          : 'Your Contribution to Team Effort',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: workout.type == 'Competitive'
                            ? Colors.deepOrange
                            : Colors.blue.shade800,
                      ),
                    ),
                  ),

                // List of exercise results
                ...workout.results.map((result) {
                  bool isSuccess = result.actualOutput >= result.exercise.targetOutput;
                  IconData icon = isSuccess ? Icons.check_circle : Icons.cancel;
                  Color iconColor = isSuccess ? Colors.green : Colors.red;

                  return ListTile(
                    leading: Icon(icon, color: iconColor, size: 30),
                    title: Text(result.exercise.name,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target: ${result.exercise.targetOutput} ${result.exercise.unit}',
                            style: TextStyle(fontSize: 14)),
                        Text('Actual: ${result.actualOutput} ${result.exercise.unit}',
                            style: TextStyle(fontSize: 14)),

                        // For competitive workouts, show position for this exercise if available
                        if (workout.type == 'Competitive' && result.ranking != null)
                          Text(
                            'Position: ${_getPositionText(result.ranking!)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getRankColor(result.ranking!),
                            ),
                          ),

                        // For collaborative workouts, show contribution percentage
                        if (workout.type == 'Collaborative' && result.teamTotal != null && result.teamTotal! > 0)
                          Text(
                            'Your contribution: ${((result.actualOutput / result.teamTotal!) * 100).toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                          ),
                      ],
                    ),
                    // Show medal icon for competitive exercises
                    trailing: workout.type == 'Competitive' && result.ranking != null && result.ranking! <= 3
                        ? Icon(
                      Icons.emoji_events,
                      color: _getMedalColor(result.ranking!),
                      size: 24,
                    )
                        : null,
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to build a rank badge
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

  // Helper method to get rank color
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

  // Helper method to get medal color
  Color _getMedalColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.blueGrey; // Silver
      case 3:
        return Colors.brown; // Bronze
      default:
        return Colors.transparent;
    }
  }

  // Helper method to get position text
  String _getPositionText(int position) {
    switch (position) {
      case 1:
        return '1st Place 🥇';
      case 2:
        return '2nd Place 🥈';
      case 3:
        return '3rd Place 🥉';
      default:
        return position.toString() + 'th Place';
    }
  }
}