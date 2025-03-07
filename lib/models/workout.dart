// In workout.dart, update the Workout class

import 'exercise_result.dart';

class Workout {
  final int? id; // Optional ID for database persistence
  final DateTime date; // The date and time of the workout
  final List<ExerciseResult> results; // List of exercise results in this workout
  final String type; // "Solo", "Collaborative", or "Competitive"
  final int? rank; // Competitive workout rank
  final int? participantCount;

  Workout({
    this.id,
    required this.date,
    required this.results,
    this.type = 'Solo', // Default to Solo
    this.rank, // Add rank
    this.participantCount,
  });

  // Update factory method
  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      date: DateTime.parse(json['date']),
      results: (json['results'] as List<dynamic>)
          .map((resultJson) => ExerciseResult.fromJson(resultJson))
          .toList(),
      type: json['type'] ?? 'Solo',
    );
  }

  // Update toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'results': results.map((result) => result.toJson()).toList(),
      'type': type,
    };
  }
}